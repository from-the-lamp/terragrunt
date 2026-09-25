terraform {
  source = "${get_repo_root()}/_modules/talos/kubernetes_upgrade"
}

locals {
  environment_vars   = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  kubernetes_version = local.environment_vars.locals.kubernetes_version
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

dependency "node_1" {
  config_path                             = "${get_repo_root()}/hetzner/hetzner/nodes/node-1"
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    ipv4_address = "127.0.0.1"
  }
}

inputs = {
  node                 = dependency.node_1.outputs.ipv4_address
  kubernetes_version   = local.kubernetes_version
  client_configuration = dependency.secrets.outputs.client_configuration
}
