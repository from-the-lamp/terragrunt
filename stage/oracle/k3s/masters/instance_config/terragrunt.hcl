include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/oracle/instance_config.hcl"
}

locals {
  environment_vars         = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env                      = local.environment_vars.locals.environment
}

dependency "vcn" {
  config_path = "${get_repo_root()}/${local.env}/oracle/vcn"
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    subnets_ids = {"k3s" = "fake-data"}
  }
}

dependency "cloudinit_config" {
  config_path = "../cloudinit_config"
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    config = {"rendered"="fake-data"}
  }
}

dependency "allow_ssh_from_all" {
  config_path = "${get_repo_root()}/${local.env}/oracle/nsg/allow_ssh_from_all"
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    id = "fake-id"
  }
}

dependency "allow_kube_api_from_all" {
  config_path = "${get_repo_root()}/${local.env}/oracle/nsg/allow_kube_api_from_all"
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    id = "fake-id"
  }
}

inputs = {
  display_name     = "k3s-master"
  assign_public_ip = true
  subnet_id        = lookup(dependency.vcn.outputs.subnets_ids, "k3s")
  user_data        = dependency.cloudinit_config.outputs.config.rendered
  nsg_ids          = [dependency.allow_ssh_from_all.outputs.id,
                      dependency.allow_kube_api_from_all.outputs.id]
}
