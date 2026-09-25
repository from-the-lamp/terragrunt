include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "common" {
  path = "${get_repo_root()}/_common/talos/os_upgrade.hcl"
}

dependency "node_1" {
  config_path                             = "${get_repo_root()}/hetzner/hetzner/nodes/node-1"
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    ipv4_address = "127.0.0.1"
  }
}

inputs = {
  node = dependency.node_1.outputs.ipv4_address
}
