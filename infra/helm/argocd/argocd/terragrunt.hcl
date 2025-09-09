include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "common" {
  path = "${get_repo_root()}/_common/kubernetes/helm.hcl"
}

locals {
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env              = local.environment_vars.locals.environment
}

dependency "oci_cloud_controller_manager" {
  config_path                             = "${get_repo_root()}/${local.env}/helm/kube-system/oci-cloud-controller-manager"
  mock_outputs_allowed_terraform_commands = ["apply", "plan", "validate", "output", "init", "destroy"]
  skip_outputs                            = true
}

inputs = {
  helm_chart_name    = "lamp-argocd"
  helm_chart_version = "0.0.2"
  helm_values        = [file("./values.yaml")]
  helm_set_sensitive = {
    "defaultClusterName"              = local.env
    "argo-cd.global.domain"           = "argocd.internal.from-the-lamp.work"
    "argo-cd.configs.cm.dex\\.config" = <<-EOT
      connectors:
        - type: gitlab
          id: ArgoCD
          name: GitLab
          useLoginAsID: false
          config:
            baseURL: https://gitlab.com
            redirectURI: https://argocd.internal.from-the-lamp.work/api/dex/callback
            clientID: $argocd-sso-secrets:clientId
            clientSecret: $argocd-sso-secrets:clientSecret
            useLoginAsID: false
    EOT
  }
}
