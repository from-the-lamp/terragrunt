include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/oracle/nlb_backend.hcl"
}

dependency "instance_pool" {
  config_path = "../instance_pool"
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "output", "init"]
  mock_outputs = {
    instance_ids = "fake-ids"
  }
}

inputs = {
  display_name = "k3s-workers"
  target_ids   = dependency.instance_pool.outputs.instance_ids
  port         = 443
}
