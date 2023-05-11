include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/helm.hcl"
}

locals {
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  dns_zone_name    = local.environment_vars.locals.dns_zone_name
}

dependency "ististio-ingressgateway" {
  config_path  = "../istio-ingressgateway"
  skip_outputs = true
}

inputs = {
  helm_internal_repo = true
  helm_chart_name    = "istio-gateway"
  helm_chart_version = "0.0.2"
  helm_addition_setting = {
    "hosts[0]" = "${local.dns_zone_name}"
    "hosts[1]" = "*.${local.dns_zone_name}"
  }
}