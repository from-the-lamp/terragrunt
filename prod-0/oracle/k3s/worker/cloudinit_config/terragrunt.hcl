include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "common" {
  path = "${get_repo_root()}/_common/tools/cloudinit_config.hcl"
}

locals {
  environment_vars    = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env                 = local.environment_vars.locals.environment
  oracle_profile_name = local.environment_vars.locals.oracle_profile_name
  common_settings     = read_terragrunt_config("${get_repo_root()}/root.hcl")
  k3s_cluster_version = local.common_settings.locals.k3s_cluster_version
  compartment_ocid    = run_cmd("--terragrunt-quiet", "${get_repo_root()}/.kek.sh", "compartment_ocid", "${get_env("OCI_CONFIG_PATH")}", "${local.oracle_profile_name}")
}


dependency "token" {
  config_path                             = "${get_repo_root()}/${local.env}/oracle/k3s/token"
  mock_outputs_allowed_terraform_commands = ["apply", "plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    "password" = "fake-password"
  }
}

dependency "ssh_read_file_content" {
  config_path                             = "${get_repo_root()}/${local.env}/oracle/k3s/masters/ssh_read_file_content"
  mock_outputs_allowed_terraform_commands = ["apply", "plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    file_contents = { "/etc/rancher/k3s/server-ip" = "fake-data" }
  }
}

inputs = {
  content = "${get_repo_root()}/_common/oracle/scripts/k3s.sh"
  vars = {
    compartment_ocid = local.compartment_ocid
    k3s_version      = local.k3s_cluster_version
    k3s_master_host  = lookup(dependency.ssh_read_file_content.outputs.file_contents, "/etc/rancher/k3s/server-ip")
    k3s_token        = dependency.token.outputs.password
    k3s_node_label   = "node-role=worker"
  }
}
