terraform {
  source = "${local.private_modules_base_url}/${local.module_name}//${local.module_subdir}?ref=${local.module_version}"
}

locals {
  module_name              = "oracle"
  module_subdir            = "instance_config"
  module_version           = "main"
  common_settings          = read_terragrunt_config("${get_repo_root()}/_common/settings.hcl")
  private_modules_base_url = local.common_settings.locals.private_modules_base_url
  config_file_profile      = local.common_settings.locals.config_file_profile
  compartment_ocid         = local.common_settings.locals.compartment_ocid
  availability_domain      = local.common_settings.locals.availability_domain
  admin_ssh_pub            = local.common_settings.locals.admin_ssh_pub
}

inputs = {
  config_file_profile = local.config_file_profile
  compartment_ocid    = local.compartment_ocid
  availability_domain = local.availability_domain
  admin_ssh_pub       = local.admin_ssh_pub
}
