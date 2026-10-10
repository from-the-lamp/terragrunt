# Not wired through _common/talos/apply_config.hcl - that file hardcodes
# dependency "machine_config" at hetzner/talos/machine_config/controlplane,
# which doesn't apply here. Self-contained instead, same as how Hetzner's
# own apply_config/node-N units each duplicate their node-specific
# dependency block rather than sharing it.
#
# This unit is for RE-applying config to an already-bootstrapped node
# (version bumps, patch changes) - the very first config application
# happens outside Terraform: the node fetches it over the LAN from the
# router at boot (see homelab/README.md). talos_machine_bootstrap
# (homelab/talos/access) also needs the node already configured and
# reachable, which that first-boot fetch provides.
include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_repo_root()}/_modules/talos/apply_config"
}

locals {
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  node_1_ip        = local.environment_vars.locals.node_1_ip
}

dependency "secrets" {
  config_path                             = "${get_repo_root()}/homelab/talos/secrets"
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
  config_path                             = "${get_repo_root()}/homelab/talos/machine_config/node-1"
  mock_outputs_allowed_terraform_commands = ["validate", "output", "init", "destroy"]
  mock_outputs = {
    machine_configuration = "fake-config"
  }
}

inputs = {
  node                  = local.node_1_ip
  machine_configuration = dependency.machine_config.outputs.machine_configuration
  client_configuration  = dependency.secrets.outputs.client_configuration
}
