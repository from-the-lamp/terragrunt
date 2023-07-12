terraform {
  source = "${local.private_modules_base_url}/${local.module_name}//?ref=${local.module_version}"
}

locals {
  module_name              = "tools"
  module_version           = "main"
  common_settings          = read_terragrunt_config("${get_repo_root()}/_common/settings.hcl")
  private_modules_base_url = local.common_settings.locals.private_modules_base_url
  compartment_ocid         = local.common_settings.locals.compartment_ocid
  availability_domain      = local.common_settings.locals.availability_domain  
}
