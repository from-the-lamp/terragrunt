terraform {
  source = "${local.modules_url}/${local.module_name}//${local.module_dir}?ref=${local.module_version}"
}

locals {
  common_settings = read_terragrunt_config("${get_repo_root()}/terragrunt.hcl")
  modules_url = local.common_settings.locals.private_modules_base_url
  module_name = "tools"
  module_dir = "cloudinit_config"
  module_version = "main"
  compartment_ocid = local.common_settings.locals.compartment_ocid
  availability_domain = local.common_settings.locals.availability_domain
}

inputs = {
  content = "${get_repo_root()}/_common/oracle/scripts/k3s.sh"
  vars = {
    compartment_ocid = local.compartment_ocid
    availability_domain = local.availability_domain
  }
}
