include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/helm.hcl"
}

locals {
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env = local.environment_vars.locals.environment
}

inputs = {
  helm_external_repo    = true
  helm_values_file      = "values.yml"
  helm_chart_name       = "base"
  helm_repo_url         = "https://istio-release.storage.googleapis.com/charts"
  helm_chart_version    = "1.16.1"
}
