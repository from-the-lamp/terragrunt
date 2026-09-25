include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "common" {
  path = "${get_repo_root()}/_common/hetzner/load_balancer.hcl"
}

dependency "network" {
  config_path                             = "${get_repo_root()}/hetzner/hetzner/network"
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    id = 1
  }
}

inputs = {
  network_id = dependency.network.outputs.id
}
