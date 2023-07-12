terraform {
  source = "${local.private_modules_base_url}/${local.module_name}//?ref=${local.module_version}"
}

locals {
  module_name              = "cloudinit_config"
  module_version           = "main"
  common_settings          = read_terragrunt_config("${get_repo_root()}/_common/settings.hcl")
  private_modules_base_url = local.common_settings.locals.private_modules_base_url
  compartment_ocid         = local.common_settings.locals.compartment_ocid
  availability_domain      = local.common_settings.locals.availability_domain  
}

inputs = {
  content = "${get_repo_root()}/_common/oracle/scripts/k3s.sh"
  vars    = {
    compartment_ocid    = local.compartment_ocid
    availability_domain = local.availability_domain
    k3s_url             = "123"
    k3s_token           = "1234"
    k3s_version         = "latest"
    is_k3s_master       = "true"
  }
}
