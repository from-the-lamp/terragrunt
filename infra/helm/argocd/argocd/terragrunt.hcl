include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/kubernetes/helm.hcl"
}

locals {
  environment_vars    = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env                 = local.environment_vars.locals.environment
  common_settings     = read_terragrunt_config("${get_repo_root()}/terragrunt.hcl")
  infra_helm_repo_url = local.common_settings.locals.infra_helm_repo_url
}

dependency "oci_cloud_controller_manager" {
  config_path                             = "${get_repo_root()}/${local.env}/helm/kube-system/oci-cloud-controller-manager"
  mock_outputs_allowed_terraform_commands = ["apply", "plan", "validate", "output", "init", "destroy"]
  skip_outputs                            = true
}

inputs = {
  helm_repo_url      = "https://argoproj.github.io/argo-helm"
  helm_chart_name    = "argo-cd"
  helm_chart_version = "7.4.2"
  helm_values_file   = file("values.yaml")
  helm_set_sensitive = {
    "configs.cm.dex\\.config"                = <<-EOT
        connectors:
        - type: gitlab
          id: ArgoCD
          name: GitLab
          useLoginAsID: false
          config:
            baseURL: https://gitlab.com
            redirectURI: https://argocd.from-the-lamp.work/api/dex/callback
            clientID: ${get_env("OPENID_CLIENT_ID_ARGOCD")}
            clientSecret: ${get_env("OPENID_CLIENT_SECRET_ARGOCD")}
            useLoginAsID: false
        staticClients:
          - id: argo-workflows-sso
            name: Argo Workflow
            redirectURIs:
              - https://workflow.from-the-lamp.work/oauth2/callback
            secretEnv: ARGO_WORKFLOWS_SSO_CLIENT_SECRET
    EOT
    "notifications.secret.items.slack-token" = get_env("ARGOCD_SLACK_TOKEN")
  }
}
