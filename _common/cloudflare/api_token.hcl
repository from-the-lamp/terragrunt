terraform {
  source = "${local.private_modules_base_url}/${local.module_name}//${local.module_subdir}?ref=${local.module_version}"
}

locals {
  module_name              = "cloudflare"
  module_subdir            = "api_token"
  module_version           = "main"
  private_modules_base_url = local.common_settings.locals.private_modules_base_url
  environment_vars         = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env                      = local.environment_vars.locals.environment
  common_settings          = read_terragrunt_config("${get_repo_root()}/_common/settings.hcl")
  group_vars               = read_terragrunt_config(find_in_parent_folders("group.hcl"))
  infra_zone               = local.environment_vars.locals.infra_zone
  gitlab_group_name        = local.group_vars.locals.gitlab_group_name
}

dependency "gitlab_vars" {
  config_path = "${get_repo_root()}/${local.env}/gitlab/get_infra_variables"
  mock_outputs_allowed_terraform_commands = ["apply", "plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    "map_variables.cloudflare_api_token" = "fake-token"
  }
}

inputs = {
  cloudflare_api_token  = dependency.gitlab_vars.outputs.map_variables.cloudflare_api_token
  cloudflare_zone_name  = local.infra_zone
  cloudflare_token_name = "${local.gitlab_group_name}_purge_cache"
}
