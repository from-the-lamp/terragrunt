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
  fingerprint         = run_cmd("--terragrunt-quiet", "${get_repo_root()}/.kek.sh", "fingerprint", "${get_env("OCI_CONFIG_PATH")}", "${local.oracle_profile_name}")
  tenancy             = run_cmd("--terragrunt-quiet", "${get_repo_root()}/.kek.sh", "tenancy", "${get_env("OCI_CONFIG_PATH")}", "${local.oracle_profile_name}")
  key_file            = run_cmd("--terragrunt-quiet", "${get_repo_root()}/.kek.sh", "key_file", "${get_env("OCI_CONFIG_PATH")}", "${local.oracle_profile_name}")
  region              = run_cmd("--terragrunt-quiet", "${get_repo_root()}/.kek.sh", "region", "${get_env("OCI_CONFIG_PATH")}", "${local.oracle_profile_name}")
  user                = run_cmd("--terragrunt-quiet", "${get_repo_root()}/.kek.sh", "user", "${get_env("OCI_CONFIG_PATH")}", "${local.oracle_profile_name}")
}

dependency "vault_infra" {
  config_path                             = "${get_repo_root()}/${local.env}/oracle/vaults/infra"
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    vault_id = "fake-id"
  }
}

inputs = {
  helm_chart_name    = "lamp-external-secrets-stores"
  helm_chart_version = "0.0.1"
  helm_set_sensitive = {
    "clusterStore.privateKey"  = base64encode(file(local.key_file))
    "clusterStore.fingerprint" = local.fingerprint
    "clusterStore.user"        = local.user
    "clusterStore.tenancy"     = local.tenancy
    "clusterStore.ocid"        = dependency.vault_infra.outputs.vault_id
    "clusterStore.region"      = local.region
  }
}
