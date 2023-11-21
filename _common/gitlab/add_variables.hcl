terraform {
  source = "${local.modules_url}/${local.module_name}//${local.module_dir}?ref=${local.module_version}"
}

locals {
  common_settings = read_terragrunt_config("${get_repo_root()}/terragrunt.hcl")
  modules_url = local.common_settings.locals.private_modules_base_url
  module_name = "gitlab"
  module_dir = "add_variables"
  module_version = "main"
  gitlab_token = local.common_settings.locals.gitlab_token
  local_modules_base_path = local.common_settings.locals.local_modules_base_path
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env = local.environment_vars.locals.environment
  gitlab_group_vars = read_terragrunt_config(find_in_parent_folders("group.hcl"))
  gitlab_group_name = local.gitlab_group_vars.locals.gitlab_group_full_path
}

inputs = {
  gitlab_token = local.gitlab_token
  gitlab_group_name = local.gitlab_group_name
}
