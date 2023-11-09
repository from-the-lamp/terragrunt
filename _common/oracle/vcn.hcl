terraform {
  source = "${local.modules_url}/${local.module_name}//${local.module_dir}?ref=${local.module_version}"
}

locals {
  common_settings = read_terragrunt_config("${get_repo_root()}/terragrunt.hcl")
  modules_url = local.common_settings.locals.private_modules_base_url
  module_name = "oracle"
  module_dir = "vcn"
  module_version = "main"
  compartment_ocid = local.common_settings.locals.compartment_ocid
  availability_domain = local.common_settings.locals.availability_domain  
}

inputs = {
  compartment_ocid = local.compartment_ocid
  availability_domain = local.availability_domain
  vcn_name = "default"
  vcn_dns_label = "default"
  vcn_internet_gateway_enabled = true
  vcn_internet_gateway_name = "default"
  oci_core_vcn_cidr = "10.0.0.0/16"
  vcn_subnets = {
    k3s = {
      cidr_block = "10.0.1.0/24"
      display_name = "k3s"
      dns_label = "k3s"
    }
  }
}
