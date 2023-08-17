terraform {
  source = "${local.private_modules_base_url}/${local.module_name}//${local.module_subdir}?ref=${local.module_version}"
}

locals {
  module_name              = "gitlab"
  module_subdir            = "add_variables"
  module_version           = "main"
  private_modules_base_url = local.common_settings.locals.private_modules_base_url
  environment_vars         = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env                      = local.environment_vars.locals.environment
  common_settings          = read_terragrunt_config("${get_repo_root()}/_common/settings.hcl")
  gitlab_token             = local.common_settings.locals.gitlab_token
  local_modules_base_path  = local.common_settings.locals.local_modules_base_path
  gitlab_group_vars        = read_terragrunt_config(find_in_parent_folders("group.hcl"))
  gitlab_group_id          = local.gitlab_group_vars.locals.gitlab_group_id
}

inputs = {
  gitlab_token      = local.gitlab_token
  gitlab_group_id   = local.gitlab_group_id
  environment_scope = local.env
}
