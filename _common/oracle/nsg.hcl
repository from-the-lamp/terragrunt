terraform {
  source = "${local.private_modules_base_url}/${local.module_name}//${local.module_subdir}?ref=${local.module_version}"
}

locals {
  module_name              = "oracle"
  module_subdir            = "nsg"
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
  compartment_ocid = local.compartment_ocid
  ingress_rules = {
    default = [
        {
        protocol = "1"
        source   = var.my_public_ip_cidr
        description = "Allow icmp from  ${var.my_public_ip_cidr}"
        },
        {
        protocol = "6"
        source   = var.my_public_ip_cidr
        description = "Allow SSH from ${var.my_public_ip_cidr}"
        min = 22
        max = 22
        },
        {
        protocol = "all"
        source   = var.oci_core_vcn_cidr
        description = "Allow all from vcn subnet"
        }
    ]
    }
}
