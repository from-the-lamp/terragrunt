terraform {
  source = "${local.private_modules_base_url}/${local.module_name}//?ref=${local.module_version}"
}

locals {
  module_name              = "gitlab-variables"
  module_version           = "main"
  environment_vars         = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env                      = "${local.environment_vars.locals.environment}"
  common_settings          = read_terragrunt_config("${get_repo_root()}/_common/common_settings.hcl")
  gitlab_token             = "${local.common_settings.locals.gitlab_token}"
  private_modules_base_url = "${local.common_settings.locals.private_modules_base_url}"
}

inputs = {
  gitlab_project_id = "40541314"
  gitlab_token      = local.gitlab_token
}
