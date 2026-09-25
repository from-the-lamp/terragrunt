include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "common" {
  path = "${get_repo_root()}/_common/hetzner/server.hcl"
}

dependency "network" {
  config_path                             = "${get_repo_root()}/hetzner/hetzner/network"
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    id = 1
  }
}

dependency "firewall" {
  config_path                             = "${get_repo_root()}/hetzner/hetzner/firewall"
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    id = 1
  }
}

dependency "machine_config" {
  config_path                             = "${get_repo_root()}/hetzner/talos/machine_config/controlplane"
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    machine_configuration = "fake-config"
  }
}

dependency "talos_image" {
  config_path                             = "${get_repo_root()}/hetzner/hetzner/talos_image"
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    id = "fake-image-id"
  }
}

inputs = {
  name       = "hetzner-cp-3"
  network_id = dependency.network.outputs.id
  private_ip = "10.0.1.13"
  image      = dependency.talos_image.outputs.id
  firewall_ids = [
    dependency.firewall.outputs.id,
  ]
  user_data = dependency.machine_config.outputs.machine_configuration
}
