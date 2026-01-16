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
  compartment_ocid    = run_cmd("--terragrunt-quiet", "${get_repo_root()}/.kek.sh", "compartment_ocid", "${get_env("OCI_CONFIG_PATH")}", "lamp-infra")
  fingerprint         = run_cmd("--terragrunt-quiet", "${get_repo_root()}/.kek.sh", "fingerprint", "${get_env("OCI_CONFIG_PATH")}", "lamp-infra")
  tenancy             = run_cmd("--terragrunt-quiet", "${get_repo_root()}/.kek.sh", "tenancy", "${get_env("OCI_CONFIG_PATH")}", "lamp-infra")
  key_file            = run_cmd("--terragrunt-quiet", "${get_repo_root()}/.kek.sh", "key_file", "${get_env("OCI_CONFIG_PATH")}", "lamp-infra")
  region              = run_cmd("--terragrunt-quiet", "${get_repo_root()}/.kek.sh", "region", "${get_env("OCI_CONFIG_PATH")}", "lamp-infra")
  user                = run_cmd("--terragrunt-quiet", "${get_repo_root()}/.kek.sh", "user", "${get_env("OCI_CONFIG_PATH")}", "lamp-infra")
}

dependency "vault_infra" {
  config_path                             = "${get_repo_root()}/infra/oracle/vaults/infra"
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    vault_id = "fake-id"
  }
}

inputs = {
  helm_chart_name    = "lamp-external-secrets-stores"
  helm_chart_version = "0.0.2"
  helm_set_sensitive = {
    "clusterStores[0].name"        = "oracle"
    "clusterStores[0].privateKey"  = base64encode(file(local.key_file))
    "clusterStores[0].fingerprint" = local.fingerprint
    "clusterStores[0].user"        = local.user
    "clusterStores[0].tenancy"     = local.tenancy
    "clusterStores[0].ocid"        = dependency.vault_infra.outputs.vault_id
    "clusterStores[0].region"      = local.region
  }
}
