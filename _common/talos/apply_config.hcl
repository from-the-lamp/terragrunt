terraform {
  source = "${get_repo_root()}/_modules/talos/apply_config"
}

dependency "secrets" {
  config_path = "${get_repo_root()}/hetzner/talos/secrets"
  # "plan" deliberately excluded: consumed as real PEM material by a live
  # provisioner; a mock value would crash instead of a clean "not applied
  # yet" error.
  mock_outputs_allowed_terraform_commands = ["validate", "output", "init", "destroy"]
  mock_outputs = {
    client_configuration = {
      ca_certificate     = "fake"
      client_certificate = "fake"
      client_key         = "fake"
    }
  }
}

dependency "machine_config" {
  config_path                             = "${get_repo_root()}/hetzner/talos/machine_config/controlplane"
  mock_outputs_allowed_terraform_commands = ["validate", "output", "init", "destroy"]
  mock_outputs = {
    machine_configuration = "fake-config"
  }
}

inputs = {
  machine_configuration = dependency.machine_config.outputs.machine_configuration
  client_configuration  = dependency.secrets.outputs.client_configuration
}
