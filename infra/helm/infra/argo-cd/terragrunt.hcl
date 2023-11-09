include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/k8s/helm.hcl"
}

locals {
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env = local.environment_vars.locals.environment
  infra_zone = local.environment_vars.locals.infra_zone
  versions = read_terragrunt_config("${get_repo_root()}/_common/versions.hcl")
  argo_cd = local.versions.locals.argo_cd
  common_settings = read_terragrunt_config("${get_repo_root()}/terragrunt.hcl")
  infra_helm_repo_url = local.common_settings.locals.infra_helm_repo_url
}

dependency "get_infra_variables" {
  config_path = "${get_repo_root()}/${local.env}/gitlab/get_infra_variables"
  mock_outputs_allowed_terraform_commands = ["apply" ,"plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    variables = {
      cloudflare_api_token = "fake-token"
      gitlab_openid_secret = "fake-secret"
    }
  }
}

dependency "k8s_data_prod" {
  config_path = "${get_repo_root()}/prod/oracle/k3s/masters/ssh_read_file_content"
  mock_outputs_allowed_terraform_commands = ["apply", "plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    file_contents = {
      "/etc/rancher/k3s/server-ip" = "ZmFrZS1kYXRhCg==",
      "/etc/rancher/k3s/server-certificate-authority-data" = "ZmFrZS1kYXRhCg==",
      "/etc/rancher/k3s/client-certificate-data" = "ZmFrZS1kYXRhCg==",
      "/etc/rancher/k3s/client-key-data" = "ZmFrZS1kYXRhCg==",
    }
  }
}

inputs = {
  helm_repo_url = "https://argoproj.github.io/argo-helm"
  helm_chart_version = local.argo_cd
  helm_set_sensitive = {
    "configs.secret.gitlabSecret" = dependency.get_infra_variables.outputs.variables.gitlab_openid_secret
    "configs.clusterCredentials[0].config.tlsClientConfig.caData" = lookup(dependency.k8s_data_prod.outputs.file_contents, "/etc/rancher/k3s/server-certificate-authority-data")
    "configs.clusterCredentials[0].config.tlsClientConfig.certData" = lookup(dependency.k8s_data_prod.outputs.file_contents, "/etc/rancher/k3s/client-certificate-data")
    "configs.clusterCredentials[0].config.tlsClientConfig.keyData" = lookup(dependency.k8s_data_prod.outputs.file_contents, "/etc/rancher/k3s/client-key-data")
    "configs.repositories.devops.url" = local.infra_helm_repo_url
  }
  helm_values_file = <<-EOF
  configs:
    cm:
      url: https://argocd.${local.infra_zone}
      admin.enabled: "false"
      exec.enabled: true
      accounts.gitlab-ci-user: apiKey
      dex.config: |
        connectors:
        - type: gitlab
          id: ArgoCD
          name: GitLab
          useLoginAsID: false
          config:
            baseURL: https://gitlab.com
            redirectURI: https://argocd.${local.infra_zone}/api/dex/callback
            clientID: 2fd7eebea2c98fcc945b386fef203dfdc21b066f53cd23307baa9844264ff32e
            clientSecret: $webhook.gitlab.secret
            useLoginAsID: false
    params:
      server.insecure: true
      application.namespaces: "*"
      createClusterRoles: true
    clusterCredentials:
      - name: prod
        server: https://${lookup(dependency.k8s_data_prod.outputs.file_contents, "/etc/rancher/k3s/server-ip")}:6443
        labels: {}
        annotations: {}
        config:
          tlsClientConfig:
            insecure: false
    rbac:
      policy.default: role:readonly
      policy.csv: |
        p, role:release-admin, applications, *, */*, allow
        p, role:release-admin, clusters, get, *, allow
        p, role:release-admin, repositories, get, *, allow
        p, role:release-admin, repositories, create, *, allow
        p, role:release-admin, repositories, update, *, allow
        p, role:release-admin, repositories, delete, *, allow
        g, from-the-lamp, role:admin
        g, infra, role:admin
        g, gitlab-ci-user, role:release-admin
        g, frontend, role:release-admin
        g, backend, role:release-admin
    repositories:
      devops:
        name: infra
        type: helm
  EOF
}
