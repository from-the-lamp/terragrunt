include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/oracle/instance.hcl"
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

dependency "oci-cloud-controller-manager" {
  config_path                             = "${get_repo_root()}/${local.env}/helm/kube-system/oci-cloud-controller-manager"
  mock_outputs_allowed_terraform_commands = ["apply", "plan", "validate", "output", "init", "destroy"]
  skip_outputs                            = true
}

inputs = {
  display_name = "k3s-worker"
  subnet_id    = lookup(dependency.vcn.outputs.subnets_ids, "k3s")
  user_data    = dependency.cloudinit_config.outputs.config.rendered
}
