include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${local.modules_url}/${local.module_dir}?tag=${local.module_version}"
}

locals {
  common_settings = read_terragrunt_config("${get_repo_root()}/root.hcl")
  modules_url     = local.common_settings.locals.private_modules_base_url
  module_dir      = "oneuptime/project_settings"
  module_version  = "0.1.0"
}

include "oneuptime_provider" {
  path = "${get_repo_root()}/_common/oneuptime/provider.hcl"
}

inputs = {
  project_id = "20d35059-271e-4472-9849-d9ca99582870"
  name       = "from-the-lamp"
}
