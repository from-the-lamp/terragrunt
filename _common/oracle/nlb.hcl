terraform {
  source = "${local.private_modules_base_url}/${local.module_name}//${local.module_subdir}?ref=${local.module_version}"
}

locals {
  module_name              = "oracle"
  module_subdir            = "nlb"
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

dependency "vcn" {
  config_path = "${get_repo_root()}/${local.env}/oracle/vcn"
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "output", "init"]
  mock_outputs = {
    vcn_id      = "fake-id"
    subnets_ids = "fake-ids"
  }
}

dependency "allow_https_from_all" {
  config_path = "${get_repo_root()}/${local.env}/oracle/nsg/allow_https_from_all"
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "output", "init"]
  mock_outputs = {
    id = "fake-id"
  }
}

inputs = {
  compartment_ocid           = local.compartment_ocid
  subnet_id                  = lookup(dependency.vcn.outputs.subnets_ids, "k3s")
  display_name               = "k3s"
  network_security_group_ids = [dependency.allow_https_from_all.outputs.id]
}
