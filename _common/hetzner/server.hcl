terraform {
  source = "${get_repo_root()}/_modules/hetzner/server"
}

locals {
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  hetzner_location = local.environment_vars.locals.hetzner_location
  node_server_type = local.environment_vars.locals.node_server_type
}

# Same client_configuration for every node (not per-node bootstrap_node_id
# like talos/access) — safe to depend on talos/secrets directly here instead
# of repeating this dependency in every node unit.
dependency "secrets" {
  config_path = "${get_repo_root()}/hetzner/talos/secrets"
  # "plan" deliberately excluded: these are consumed as real PEM material in
  # a destroy-time provisioner; a mock value would only ever matter if this
  # unit were destroyed while secrets had no state, which should never happen.
  mock_outputs_allowed_terraform_commands = ["validate", "output", "init", "destroy"]
  mock_outputs = {
    client_configuration = {
      ca_certificate     = "fake"
      client_certificate = "fake"
      client_key         = "fake"
    }
  }
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "hcloud" {
  token = "${get_env("HETZNER_API_TOKEN")}"
}
EOF
}

inputs = {
  server_type              = local.node_server_type
  location                 = local.hetzner_location
  talos_ca_certificate     = dependency.secrets.outputs.client_configuration.ca_certificate
  talos_client_certificate = dependency.secrets.outputs.client_configuration.client_certificate
  talos_client_key         = dependency.secrets.outputs.client_configuration.client_key
  labels = {
    role = "controlplane"
  }
}
