include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/k8s/helm.hcl"
}

locals {
  environment_vars     = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env                  = local.environment_vars.locals.environment
  common_settings      = read_terragrunt_config("${get_repo_root()}/_common/settings.hcl")
  compartment_ocid     = local.common_settings.locals.compartment_ocid
  region               = local.common_settings.locals.region
  versions             = read_terragrunt_config("${get_repo_root()}/_common/versions.hcl")
  istio_system_version = local.versions.locals.istio_system
}

inputs = {
  helm_external_repo = true
  helm_repo_url      = "https://istio-release.storage.googleapis.com/charts"
  helm_chart_name    = "istiod"
  helm_chart_version = local.istio_system_version
  k8s_namespace      = "istio-system"
}
