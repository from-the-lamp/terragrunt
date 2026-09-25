include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "common" {
  path = "${get_repo_root()}/_common/talos/os_upgrade.hcl"
}

dependency "node_2" {
  config_path                             = "${get_repo_root()}/hetzner/hetzner/nodes/node-2"
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    ipv4_address = "127.0.0.2"
  }
}

# Enforces serial upgrades: node-2 won't even start until node-1's upgrade
# (including its own etcd-health wait) has completed. Replacing all etcd
# members' OS at once is exactly what broke quorum earlier — never do this
# in parallel.
dependency "previous" {
  config_path                             = "${get_repo_root()}/hetzner/talos/os_upgrade/node-1"
  mock_outputs_allowed_terraform_commands = ["plan", "apply", "validate", "output", "init", "destroy"]
  skip_outputs                            = true
}

inputs = {
  node = dependency.node_2.outputs.ipv4_address
}
