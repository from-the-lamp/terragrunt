terraform {
  source = "${local.modules_url}/${local.module_name}//${local.module_dir}?ref=${local.module_version}"
}

locals {
  common_settings = read_terragrunt_config("${get_repo_root()}/terragrunt.hcl")
  modules_url = local.common_settings.locals.private_modules_base_url
  module_name = "rancher"
  module_dir = "bootstrap"
  module_version = "main"
}

inputs = {
  api_url = "https://rancher.from-the-lamp.work"
}
