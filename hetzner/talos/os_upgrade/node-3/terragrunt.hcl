include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "common" {
  path = "${get_repo_root()}/_common/talos/os_upgrade.hcl"
}

dependency "node_3" {
  config_path                             = "${get_repo_root()}/hetzner/hetzner/nodes/node-3"
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    ipv4_address = "127.0.0.3"
  }
}

dependency "previous" {
  config_path                             = "${get_repo_root()}/hetzner/talos/os_upgrade/node-2"
  mock_outputs_allowed_terraform_commands = ["plan", "apply", "validate", "output", "init", "destroy"]
  skip_outputs                            = true
}

inputs = {
  node = dependency.node_3.outputs.ipv4_address
}
