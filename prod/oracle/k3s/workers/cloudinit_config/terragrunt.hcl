include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/tools/cloudinit_config.hcl"
}

locals {
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env = local.environment_vars.locals.environment
  common_settings = read_terragrunt_config("${get_repo_root()}/terragrunt.hcl")
  compartment_ocid = local.common_settings.locals.compartment_ocid
  availability_domain = local.common_settings.locals.availability_domain
  versions = read_terragrunt_config("${get_repo_root()}/_common/versions.hcl")
  k3s_cluster = local.versions.locals.k3s_cluster
}

dependency "token" {
  config_path =  "${get_repo_root()}/${local.env}/oracle/k3s/token"
  mock_outputs_allowed_terraform_commands = ["apply" ,"plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    "password" = "fake-password"
  }
}

dependency "ssh_read_file_content" {
  config_path = "${get_repo_root()}/${local.env}/oracle/k3s/masters/ssh_read_file_content"
  mock_outputs_allowed_terraform_commands = ["apply", "plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    file_contents = {"/etc/rancher/k3s/server-ip" = "fake-data"}
  }
}

inputs = {
  content = "${get_repo_root()}/_common/oracle/scripts/k3s.sh"
  vars    = {
    compartment_ocid = local.compartment_ocid
    availability_domain = local.availability_domain
    k3s_version = local.k3s_cluster
    k3s_master_host = lookup(dependency.ssh_read_file_content.outputs.file_contents, "/etc/rancher/k3s/server-ip")
    k3s_token = dependency.token.outputs.password
    k3s_node_label = "node-role=worker"
  }
}
