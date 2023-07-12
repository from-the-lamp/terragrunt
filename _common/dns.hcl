terraform {
  source = "${local.private_modules_base_url}/${local.module_name}//${local.module_subdir}?ref=${local.module_version}"
}

locals {
  module_name              = "cloudflare"
  module_subdir            = "dns_record"
  module_version           = "main"
  private_modules_base_url = local.common_settings.locals.private_modules_base_url
  common_settings          = read_terragrunt_config("${get_repo_root()}/_common/settings.hcl")
  environment_vars         = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env                      = local.environment_vars.locals.environment
  infra_zone               = local.environment_vars.locals.infra_zone
}

dependency "get_infra_variables" {
  config_path = "${get_repo_root()}/${local.env}/gitlab/get_infra_variables"
  mock_outputs_allowed_terraform_commands = ["apply" ,"plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    "map_variables.cloudflare_api_token" = "fake-token"
  }
}

dependency "nlb" {
  config_path = "${get_repo_root()}/${local.env}/oracle/nlb"
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "output", "init"]
  mock_outputs = {
    ip = "1.2.3.4"
  }
}

inputs = {
  cloudflare_api_token = dependency.get_infra_variables.outputs.map_variables.cloudflare_api_token
  cloudflare_zone_name = local.infra_zone
  global_address       = dependency.nlb.outputs.ip
}
