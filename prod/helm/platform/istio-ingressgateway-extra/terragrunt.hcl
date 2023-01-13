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

dependency "ististio-ingressgatewayio" {
  config_path  = "${get_repo_root()}/${local.env}/helm/platform/istio-ingressgateway"
  skip_outputs = true
}

inputs = {
  helm_local_repo = true
  k8s_namespace   = "istio-system"
}
