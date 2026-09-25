include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "common" {
  path = "${get_repo_root()}/_common/talos/apply_config.hcl"
}

dependency "node_2" {
  config_path                             = "${get_repo_root()}/hetzner/hetzner/nodes/node-2"
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    ipv4_address = "127.0.0.2"
  }
}

dependency "previous" {
  config_path                             = "${get_repo_root()}/hetzner/talos/apply_config/node-1"
  mock_outputs_allowed_terraform_commands = ["plan", "apply", "validate", "output", "init", "destroy"]
  skip_outputs                            = true
}

inputs = {
  node = dependency.node_2.outputs.ipv4_address
}
