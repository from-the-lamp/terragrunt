terraform {
  source = "${local.modules_url}/${local.module_name}//${local.module_dir}?ref=${local.module_version}"
}

locals {
  common_settings = read_terragrunt_config("${get_repo_root()}/terragrunt.hcl")
  modules_url = local.common_settings.locals.private_modules_base_url
  module_name = "cloudflare"
  module_dir = "api_token"
  module_version = "main"
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env = local.environment_vars.locals.environment
  dns_zone_name = local.environment_vars.locals.dns_zone_name
}

dependency "gitlab_vars" {
  config_path = "${get_repo_root()}/${local.env}/gitlab/get_infra_variables"
  mock_outputs_allowed_terraform_commands = ["apply", "plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    variables = {
      cloudflare_api_token = "fake-token"
    }
  }
}

inputs = {
  cloudflare_api_token = dependency.gitlab_vars.outputs.variables.cloudflare_api_token
  cloudflare_zone_name = local.dns_zone_name
  cloudflare_token_name = "${local.env}_purge_cache"
}
