terraform {
  source = "${local.private_modules_base_url}/${local.module_name}//${local.module_subdir}?ref=${local.module_version}"
}

locals {
  module_name              = "gitlab"
  module_subdir            = "get_variables"
  module_version           = "main"
  private_modules_base_url = local.common_settings.locals.private_modules_base_url
  environment_vars         = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env                      = local.environment_vars.locals.environment
  common_settings          = read_terragrunt_config("${get_repo_root()}/_common/settings.hcl")
  gitlab_token             = local.common_settings.locals.gitlab_token
  infra_variables_file     = local.environment_vars.locals.infra_variables_file
  infra_project_id         = local.common_settings.locals.infra_project_id
}

inputs = {
  gitlab_token            = local.gitlab_token
  gitlab_project_id       = local.infra_project_id
  gitlab_project_variable = local.infra_variables_file
}
