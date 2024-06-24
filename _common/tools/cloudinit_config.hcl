terraform {
  source = "${local.modules_url}//${local.module_dir}?ref=${local.module_version}"
}

locals {
  common_settings = read_terragrunt_config("${get_repo_root()}/terragrunt.hcl")
  modules_url = local.common_settings.locals.private_modules_base_url
  module_dir = "tools/cloudinit_config"
  module_version = "main"
}

inputs = {
  content = "${get_repo_root()}/_common/oracle/scripts/k3s.sh"
}
