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

dependency "istio" {
  config_path  = "${get_repo_root()}/${local.env}/helm/platform/istio"
  skip_outputs = true
}

dependency "istiod" {
  config_path  = "${get_repo_root()}/${local.env}/helm/platform/istiod"
  skip_outputs = true
}

inputs = {
  helm_external_repo    = true
  helm_values_file      = "values.yml"
  helm_chart_name       = "gateway"
  helm_repo_url         = "https://istio-release.storage.googleapis.com/charts"
  helm_chart_version    = "1.16.1"
  k8s_namespace         = "istio-system"
}

  # after_script:
  #   - kubectl create ns infra || true
  #   - kubectl create ns frontend || true
  #   - kubectl create ns backend || true
  #   - kubectl label namespace infra istio-injection=enabled || true
  #   - kubectl label namespace frontend istio-injection=enabled || true
  #   - kubectl label namespace backend istio-injection=enabled || true
