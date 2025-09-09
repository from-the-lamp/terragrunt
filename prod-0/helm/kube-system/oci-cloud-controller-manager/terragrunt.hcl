include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "common" {
  path = "${get_repo_root()}/_common/kubernetes/helm.hcl"
}

locals {
  environment_vars    = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env                 = local.environment_vars.locals.environment
  oracle_profile_name = local.environment_vars.locals.oracle_profile_name
  compartment_ocid    = run_cmd("--terragrunt-quiet", "${get_repo_root()}/.kek.sh", "compartment_ocid", "${get_env("OCI_CONFIG_PATH")}", "${local.oracle_profile_name}")
}

dependency "vcn" {
  config_path                             = "${get_repo_root()}/${local.env}/oracle/vcn"
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    vcn_id      = "fake-id"
    subnets_ids = { "k3s" = "fake-data" }
  }
}

inputs = {
  helm_chart_name    = "lamp-oci-cloud-controller-manager"
  helm_chart_version = "0.0.1"
  helm_set_sensitive = {
    "config.compartment" = local.compartment_ocid
    "config.vcn"         = dependency.vcn.outputs.vcn_id
    "config.subnet1"     = lookup(dependency.vcn.outputs.subnets_ids, "k3s")
  }
}
