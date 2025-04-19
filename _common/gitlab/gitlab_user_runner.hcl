terraform {
  source = "${local.modules_url}//${local.module_dir}?ref=${local.module_version}"
}

locals {
  common_settings  = read_terragrunt_config("${get_repo_root()}/root.hcl")
  modules_url      = local.common_settings.locals.private_modules_base_url
  module_dir       = "gitlab/gitlab_user_runner"
  module_version   = "main"
  gitlab_token     = local.common_settings.locals.gitlab_token
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env              = local.environment_vars.locals.environment
}

inputs = {
  gitlab_token = local.gitlab_token
}
