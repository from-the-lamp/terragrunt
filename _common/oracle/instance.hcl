terraform {
  source = "${local.modules_url}/${local.module_name}//${local.module_dir}?ref=${local.module_version}"
}

locals {
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env = local.environment_vars.locals.environment
  oracle_profile_name = local.environment_vars.locals.oracle_profile_name
  common_settings = read_terragrunt_config("${get_repo_root()}/terragrunt.hcl")
  modules_url = local.common_settings.locals.private_modules_base_url
  module_name = "oracle"
  module_dir = "instance"
  module_version = "main"
  admin_ssh_pub = local.common_settings.locals.admin_ssh_pub
  ad_number = local.environment_vars.locals.ad_number
  compartment_ocid = run_cmd("--terragrunt-quiet", "${get_repo_root()}/.kek.sh", "compartment_ocid", "${get_env("OCI_CONFIG_PATH")}", "${local.oracle_profile_name}")
}

inputs = {
  config_file_profile = local.oracle_profile_name
  compartment_ocid = local.compartment_ocid
  admin_ssh_pub = local.admin_ssh_pub
  ad_number = local.ad_number
}
