include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/oracle/instance_pool.hcl"
}

locals {
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env              = local.environment_vars.locals.environment
}

dependency "instance_config" {
  config_path = "../instance_config"
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "output", "init"]
  mock_outputs = {
    id = "fake-id"
  }
}

dependency "vcn" {
  config_path = "${get_repo_root()}/${local.env}/oracle/vcn"
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "output", "init"]
  mock_outputs = {
    subnets_ids = "fake-ids"
  }
}

inputs = {
  primary_subnet_id         = lookup(dependency.vcn.outputs.subnets_ids, "k3s")
  instance_configuration_id = dependency.instance_config.outputs.id
  display_name              = "k3s-master"
  size                      = 1
}
