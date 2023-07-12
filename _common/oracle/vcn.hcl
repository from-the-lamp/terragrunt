terraform {
  source = "${local.private_modules_base_url}/${local.module_name}//${local.module_subdir}?ref=${local.module_version}"
}

locals {
  module_name              = "oracle"
  module_subdir            = "vcn"
  module_version           = "main"
  common_settings          = read_terragrunt_config("${get_repo_root()}/_common/settings.hcl")
  private_modules_base_url = local.common_settings.locals.private_modules_base_url
  environment_vars         = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env                      = local.environment_vars.locals.environment
  config_file_profile      = local.common_settings.locals.config_file_profile
  compartment_ocid         = local.common_settings.locals.compartment_ocid
}

generate "oci_provider_cfg" {
  path      = "oci.generated.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
    provider "oci" {
      config_file_profile = "${local.config_file_profile}"
    }
  EOF
}

inputs = {
  compartment_ocid             = local.compartment_ocid
  vcn_name                     = "default"
  vcn_dns_label                = "default"
  vcn_internet_gateway_enabled = true
  vcn_internet_gateway_name    = "default"
  oci_core_vcn_cidr            = "10.0.0.0/16"
  vcn_subnets = {
        k3s = {
            cidr_block      = "10.0.1.0/24"
            display_name    = "k3s"
            dns_label       = "k3s"
        }
    }
}
