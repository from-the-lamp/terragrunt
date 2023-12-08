include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/k8s/helm.hcl"
}

locals {
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env = local.environment_vars.locals.environment
}

dependency "vcn" {
  config_path = "${get_repo_root()}/${local.env}/oracle/vcn"
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    vcn_id = "fake-id"
    subnets_ids = {"k3s" = "fake-data"}
  }
}

dependency "master" {
  config_path = "${get_repo_root()}/${local.env}/oracle/k3s/masters/ssh_read_file_content"
  mock_outputs_allowed_terraform_commands = ["apply" ,"plan", "validate", "output", "init", "destroy"]
  skip_outputs = true
}

inputs = {
  helm_chart_version = "0.0.1"
  helm_values_file = <<-EOF
  compartment: ${local.compartment_ocid}
  vcn: ${dependency.vcn.outputs.vcn_id}
  loadBalancer:
    subnet1: ${lookup(dependency.vcn.outputs.subnets_ids, "k3s")}
  external: true
  EOF
}
