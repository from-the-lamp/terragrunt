include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/helm.hcl"
}

locals {
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  dns_zone_name = local.environment_vars.locals.dns_zone_name
}

dependency "get_infra_variables" {
  config_path = "../../../gitlab/get_infra_variables"
  mock_outputs_allowed_terraform_commands = ["apply" ,"plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    "map_variables.config.clientID"     = "fake-clientID"
    "map_variables.config.clientSecret" = "fake-clientSecret"
    "map_variables.config.cookieSecret" = "fake-cookieSecret"
  }
}

inputs = {
  helm_external_repo    = true
  helm_repo_url         = "https://oauth2-proxy.github.io/manifests"
  helm_chart_name       = "oauth2-proxy"
  helm_chart_version    = "6.12.0"
  helm_virtual_service  = true
  helm_addition_setting = {
    "config.clientID"     = dependency.get_infra_variables.outputs.map_variables.oauth2clientID
    "config.clientSecret" = dependency.get_infra_variables.outputs.map_variables.oauth2clientSecret
    "config.cookieSecret" = dependency.get_infra_variables.outputs.map_variables.oauth2cookieSecret
    "destination.name"    = "kiali"
    "destination.port"    = "20001"
    "gateway.enabled"     = true
    "gateway.external"    = true
    "gateway.hosts[0]"    = "${basename(get_terragrunt_dir())}.${local.dns_zone_name}"
  }
}
