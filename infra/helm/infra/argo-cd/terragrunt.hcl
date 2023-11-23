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
  argo_cd_version = local.versions.locals.argo_cd
  common_settings = read_terragrunt_config("${get_repo_root()}/terragrunt.hcl")
  infra_helm_repo_url = local.common_settings.locals.infra_helm_repo_url
  argocd_openid_client_id = local.common_settings.locals.argocd_openid_client_id
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

inputs = {
  helm_repo_url = "https://argoproj.github.io/argo-helm"
  helm_chart_version = local.argo_cd_version
  helm_set_sensitive = {
    "configs.secret.gitlabSecret" = dependency.get_infra_variables.outputs.variables.argocd_openid_client_secret
  }
  helm_values_file = <<-EOF
  configs:
    cm:
      url: https://argocd.${local.infra_zone}
      admin.enabled: "false"
      exec.enabled: true
      accounts.gitlab-ci-user: apiKey
      accounts.iac: apiKey
      application.resourceTrackingMethod: annotation
      dex.config: |
        connectors:
        - type: gitlab
          id: ArgoCD
          name: GitLab
          useLoginAsID: false
          config:
            baseURL: https://gitlab.com
            redirectURI: https://argocd.${local.infra_zone}/api/dex/callback
            clientID: ${local.argocd_openid_client_id}
            clientSecret: $webhook.gitlab.secret
            useLoginAsID: false
    params:
      server.insecure: true
      application.namespaces: "*"
      createClusterRoles: true
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
        g, iac, role:admin
        g, gitlab-ci-user, role:release-admin
        g, frontend, role:release-admin
        g, backend, role:release-admin
  EOF
}
