include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/k8s/helm.hcl"
}

locals {
  environment_vars    = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  infra_zone          = local.environment_vars.locals.infra_zone
  versions            = read_terragrunt_config("${get_repo_root()}/_common/versions.hcl")
  argo_cd             = local.versions.locals.argo_cd
  common_settings     = read_terragrunt_config("${get_repo_root()}/_common/settings.hcl")
  infra_helm_repo_url = local.common_settings.locals.infra_helm_repo_url
}

inputs = {
  helm_external_repo            = true
  helm_repo_url                 = "https://argoproj.github.io/argo-helm"
  helm_chart_name               = "argo-cd"
  helm_chart_version            = local.argo_cd
  helm_virtual_service          = false
  helm_virtual_service_host     = "argocd.${local.infra_zone}"
  helm_virtual_service_svc_host = "argo-cd-argocd-server"
  helm_virtual_service_svc_port = 80
  helm_addition_setting = {
    "configs.repositories.from-the-lamp-helm-repo.url" = local.infra_helm_repo_url
  }
}
