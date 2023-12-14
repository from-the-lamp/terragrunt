include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/k8s/helm.hcl"
}

locals {
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env = local.environment_vars.locals.environment
  common_settings = read_terragrunt_config("${get_repo_root()}/terragrunt.hcl")
  infra_helm_repo_url = local.common_settings.locals.infra_helm_repo_url
  openid_client_id_argocd = local.common_settings.locals.openid_client_id_argocd
}

dependency "infra_variables" {
  config_path = "${get_repo_root()}/${local.env}/gitlab/infra_variables"
  mock_outputs_allowed_terraform_commands = ["apply" ,"plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    variables = {
      cloudflare_api_token = "fake-token"
      gitlab_openid_secret = "fake-secret"
    }
  }
}

dependency "oci_cloud_controller_manager" {
  config_path = "${get_repo_root()}/${local.env}/helm/kube-system/oci-cloud-controller-manager"
  mock_outputs_allowed_terraform_commands = ["apply" ,"plan", "validate", "output", "init", "destroy"]
  skip_outputs = true
}

inputs = {
  helm_repo_url = "https://argoproj.github.io/argo-helm"
  helm_chart_version = "5.41.2"
  helm_set_sensitive = {
    "configs.secret.gitlabSecret" = dependency.infra_variables.outputs.variables.openid_client_secret_argocd
  }
  helm_values_file = <<-EOF
  configs:
    cm:
      url: https://argocd.from-the-lamp.work
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
            redirectURI: https://argocd.from-the-lamp.work/api/dex/callback
            clientID: ${local.openid_client_id_argocd}
            clientSecret: $webhook.gitlab.secret
            useLoginAsID: false
      resource.customizations: |
        crossplane.io/CompositeResourceDefinition:
          health.lua: |
            hs = {}
            if obj.status ~= nil then
                if obj.status.conditions ~= nil then
                    for i, condition in ipairs(obj.status.conditions) do
                        if condition.type == "Ready" and condition.status == "True" then
                            hs.status = "Healthy"
                            hs.message = "Workspace is ready"
                            return hs
                        elseif condition.type == "Synced" and condition.status == "False" then
                            hs.status = "Degraded"
                            hs.message = condition.message
                            return hs
                        end
                    end
                end
            end
            hs.status = "Progressing"
            hs.message = "Waiting for workspace to be ready"
            return hs
    params:
      server.insecure: true
      dexserver.disable.tls: true
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
