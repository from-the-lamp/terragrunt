include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/k8s/helm.hcl"
}

locals {
  versions         = read_terragrunt_config("${get_repo_root()}/_common/versions.hcl")
  gateway          = local.versions.locals.gateway
  common_settings  = read_terragrunt_config("${get_repo_root()}/terragrunt.hcl")
  helm_repo_url    = local.common_settings.locals.infra_helm_repo_url
  helm_repo_user   = local.common_settings.locals.helm_repo_user
  helm_repo_pass   = local.common_settings.locals.helm_repo_pass
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env              = local.environment_vars.locals.environment
  infra_zone       = local.environment_vars.locals.infra_zone
}

inputs = {
  helm_repo_url      = "https://opensource.zalando.com/postgres-operator/charts/postgres-operator"
  helm_chart_version = "1.10.1"
}
