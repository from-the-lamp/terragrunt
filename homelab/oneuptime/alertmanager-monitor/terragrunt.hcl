include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${local.modules_url}/${local.module_dir}?tag=${local.module_version}"
}

locals {
  common_settings = read_terragrunt_config("${get_repo_root()}/root.hcl")
  modules_url     = local.common_settings.locals.private_modules_base_url
  module_dir      = "oneuptime/alertmanager_monitor"
  module_version  = "0.1.1"
}

include "oneuptime_provider" {
  path = "${get_repo_root()}/_common/oneuptime/provider.hcl"
}
