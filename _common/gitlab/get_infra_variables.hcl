terraform {
  source = "${local.modules_url}/${local.module_name}//${local.module_dir}?ref=${local.module_version}"
}

locals {
  common_settings = read_terragrunt_config("${get_repo_root()}/terragrunt.hcl")
  modules_url = local.common_settings.locals.private_modules_base_url
  module_name = "gitlab"
  module_dir = "get_file_variables"
  module_version = "main"
  gitlab_token = local.common_settings.locals.gitlab_token
  infra_project_id = local.common_settings.locals.infra_project_id
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env = local.environment_vars.locals.environment
  infra_variables_file = local.common_settings.locals.infra_variables_file
}

inputs = {
  gitlab_token = local.gitlab_token
  gitlab_project_id = local.infra_project_id
  gitlab_project_variable = local.infra_variables_file
}
