include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "common" {
  path = "${get_repo_root()}/_common/hetzner/load_balancer_target.hcl"
}

dependency "load_balancer" {
  config_path                             = "${get_repo_root()}/hetzner/hetzner/load_balancer"
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    id = 1
  }
}

dependency "node_1" {
  config_path                             = "${get_repo_root()}/hetzner/hetzner/nodes/node-1"
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    id = 1
  }
}

dependency "node_2" {
  config_path                             = "${get_repo_root()}/hetzner/hetzner/nodes/node-2"
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    id = 2
  }
}

dependency "node_3" {
  config_path                             = "${get_repo_root()}/hetzner/hetzner/nodes/node-3"
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    id = 3
  }
}

inputs = {
  load_balancer_id = dependency.load_balancer.outputs.id
  server_ids = [
    dependency.node_1.outputs.id,
    dependency.node_2.outputs.id,
    dependency.node_3.outputs.id,
  ]
}
