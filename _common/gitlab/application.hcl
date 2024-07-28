terraform {
  source = "${local.modules_url}//${local.module_dir}?ref=${local.module_version}"
}

locals {
  common_settings = read_terragrunt_config("${get_repo_root()}/terragrunt.hcl")
  modules_url     = local.common_settings.locals.private_modules_base_url
  module_dir      = "gitlab/application"
  module_version  = "main"
  gitlab_token    = local.common_settings.locals.gitlab_token
}

inputs = {
  gitlab_token = local.gitlab_token
}
