# Not wired through _common/talos/kubernetes_upgrade.hcl - that file's
# dependency "node_1" points at hetzner/hetzner/nodes/node-1, which
# doesn't exist here. Self-contained, same as the other homelab/talos/*
# units.
include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_repo_root()}/_modules/talos/kubernetes_upgrade"
}

locals {
  environment_vars   = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  kubernetes_version = local.environment_vars.locals.kubernetes_version
  node_1_ip          = local.environment_vars.locals.node_1_ip
}

dependency "secrets" {
  config_path = "${get_repo_root()}/homelab/talos/secrets"
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

inputs = {
  node                 = local.node_1_ip
  kubernetes_version   = local.kubernetes_version
  client_configuration = dependency.secrets.outputs.client_configuration
}
