include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/kubernetes/helm.hcl"
}

locals {
  env                 = include.common.locals.env
  infra_helm_repo_url = include.common.locals.env
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
  helm_chart_name  = "./chart"
  helm_repo_url    = ""
  helm_namespace   = "external-secrets"
  helm_values_file = <<-EOF
  oracle:
    vault:
      ocid: ${dependency.vault_infra.outputs.vault_id}
      region: ${local.region}
      privateKey: ${base64encode(file(local.key_file))}
      fingerprint: ${local.fingerprint}
      user: ${local.user}
      tenancy: ${local.tenancy}
  EOF
}
