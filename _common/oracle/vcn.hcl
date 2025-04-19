terraform {
  source = "${local.modules_url}//${local.module_dir}?ref=${local.module_version}"
}

locals {
  environment_vars    = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env                 = local.environment_vars.locals.environment
  oracle_profile_name = local.environment_vars.locals.oracle_profile_name
  common_settings     = read_terragrunt_config("${get_repo_root()}/root.hcl")
  modules_url         = local.common_settings.locals.private_modules_base_url
  module_dir          = "oracle/vcn"
  module_version      = "main"
  compartment_ocid    = run_cmd("--terragrunt-quiet", "${get_repo_root()}/.kek.sh", "compartment_ocid", "${get_env("OCI_CONFIG_PATH")}", "${local.oracle_profile_name}")
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "oci" {
  config_file_profile = "${local.oracle_profile_name}"
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
      cidr_block   = "10.0.1.0/24"
      display_name = "k3s"
      dns_label    = "k3s"
    }
  }
}
