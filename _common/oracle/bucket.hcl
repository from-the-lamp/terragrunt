terraform {
  source = "${local.modules_url}//${local.module_dir}?ref=${local.module_version}"
}

locals {
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env = local.environment_vars.locals.environment
  oracle_profile_name = local.environment_vars.locals.oracle_profile_name
  common_settings = read_terragrunt_config("${get_repo_root()}/terragrunt.hcl")
  modules_url = local.common_settings.locals.private_modules_base_url
  module_dir = "oracle/bucket"
  module_version = "main"
  compartment_ocid = run_cmd("--terragrunt-quiet", "${get_repo_root()}/.kek.sh", "compartment_ocid", "${get_env("OCI_CONFIG_PATH")}", "${local.oracle_profile_name}")
}

inputs = {
  config_file_profile = local.oracle_profile_name
  compartment_ocid = local.compartment_ocid
  namespace = run_cmd("--terragrunt-quiet", "/usr/bin/env", "bash", "-c", "oci --profile lamp-infra os ns get | jq '.data' -r")
  name = basename(get_terragrunt_dir())
}
