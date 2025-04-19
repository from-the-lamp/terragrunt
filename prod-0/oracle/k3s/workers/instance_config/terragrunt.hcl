include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "common" {
  path = "${get_repo_root()}/_common/oracle/instance_config.hcl"
}

locals {
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env              = local.environment_vars.locals.environment
}

dependency "vcn" {
  config_path                             = "${get_repo_root()}/${local.env}/oracle/vcn"
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    subnets_ids = { "k3s" = "fake-data" }
  }
}

dependency "cloudinit_config" {
  config_path                             = "../cloudinit_config"
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    config = { "rendered" = "fake-data" }
  }
}

inputs = {
  display_name     = "k3s-worker"
  assign_public_ip = true
  subnet_id        = lookup(dependency.vcn.outputs.subnets_ids, "k3s")
  user_data        = dependency.cloudinit_config.outputs.config.rendered
  nsg_ids          = []
}
