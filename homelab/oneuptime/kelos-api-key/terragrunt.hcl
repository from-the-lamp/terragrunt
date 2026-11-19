include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${local.modules_url}/${local.module_dir}?tag=${local.module_version}"
}

locals {
  common_settings = read_terragrunt_config("${get_repo_root()}/root.hcl")
  modules_url     = local.common_settings.locals.private_modules_base_url
  module_dir      = "oneuptime/api_key"
  module_version  = "0.1.1"
}

include "oneuptime_provider" {
  path = "${get_repo_root()}/_common/oneuptime/provider.hcl"
}

inputs = {
  name        = "kelos-incident-agent"
  description = "Kelos incident agent: reads incidents and writes internal notes, nothing else."
  expires_at  = "2028-01-01T00:00:00Z"

  permissions = [
    "ReadProjectIncident",
    "CreateIncidentInternalNote",
  ]

  vault_property = "kelos-api-key"
}
