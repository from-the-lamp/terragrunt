include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/k8s/helm.hcl"
}

locals {
  environment_vars        = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env                     = local.environment_vars.locals.environment
  common_settings         = read_terragrunt_config("${get_repo_root()}/_common/settings.hcl")
  infra_helm_repo_url     = local.common_settings.locals.infra_helm_repo_url
  versions                = read_terragrunt_config("${get_repo_root()}/_common/versions.hcl")
  argocd_apps_version     = local.versions.locals.argocd_apps
  base_helm_chart_version = local.versions.locals.base_helm_chart
}

dependency "apps-infra" {
  config_path = "../apps-infra"
  mock_outputs_allowed_terraform_commands = ["apply" ,"plan", "validate", "output", "init", "destroy"]
  skip_outputs = true
}

dependency "argocd" {
  config_path = "${get_repo_root()}/${local.env}/oracle/k3s/workers/argocd/argo-cd"
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "output", "init", "destroy"]
  skip_outputs = true
}

inputs = {
  helm_external_repo = true
  helm_repo_url      = "https://argoproj.github.io/argo-helm"
  helm_chart_name    = "argocd-apps"
  helm_chart_version = local.argocd_apps_version
  helm_addition_setting = {
    # general
    "applications[0].sources[0].repoURL"        = local.infra_helm_repo_url
    "applications[0].sources[0].targetRevision" = local.base_helm_chart_version
    "applications[0].destination.namespace"     = basename(dirname(get_terragrunt_dir()))
    "applications[0].namespace"                 = basename(dirname(get_terragrunt_dir()))
    "applications[0].project"                   = basename(dirname(get_terragrunt_dir()))
    # book
    "applications[1].sources[0].repoURL"        = local.infra_helm_repo_url
    "applications[1].sources[0].targetRevision" = local.base_helm_chart_version
    "applications[1].destination.namespace"     = basename(dirname(get_terragrunt_dir()))
    "applications[1].namespace"                 = basename(dirname(get_terragrunt_dir()))
    "applications[1].project"                   = basename(dirname(get_terragrunt_dir()))
  }
}
