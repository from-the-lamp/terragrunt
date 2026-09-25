terraform {
  source = "${get_repo_root()}/_modules/hetzner/hcloud_token_secret"
}

dependency "cluster_access" {
  config_path                             = "${get_repo_root()}/hetzner/talos/access"
  mock_outputs_allowed_terraform_commands = ["validate", "output", "init", "destroy"]
  mock_outputs = {
    kubernetes_client_configuration = {
      host               = "https://127.0.0.1:6443"
      ca_certificate     = "fake"
      client_certificate = "fake"
      client_key         = "fake"
    }
  }
}

dependency "load_balancer" {
  config_path                             = "${get_repo_root()}/hetzner/hetzner/load_balancer"
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    ipv4 = "127.0.0.1"
  }
}

dependency "network" {
  config_path                             = "${get_repo_root()}/hetzner/hetzner/network"
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    id = "1"
  }
}

# Ordering only (not used for any input): the load balancer's IP is useless
# without a healthy target behind it. Without this, `destroy` is free to
# detach the nodes from the LB before this unit's own destroy runs its
# Kubernetes API calls, which then fail with a connection error.
dependency "load_balancer_targets" {
  config_path                             = "${get_repo_root()}/hetzner/hetzner/load_balancer/targets"
  mock_outputs_allowed_terraform_commands = ["plan", "apply", "validate", "output", "init", "destroy"]
  skip_outputs                            = true
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "kubernetes" {
  host = "https://${dependency.load_balancer.outputs.ipv4}:6443"
  client_certificate     = <<EOT
${base64decode(dependency.cluster_access.outputs.kubernetes_client_configuration.client_certificate)}
EOT
  client_key             = <<EOT
${base64decode(dependency.cluster_access.outputs.kubernetes_client_configuration.client_key)}
EOT
  cluster_ca_certificate = <<EOT
${base64decode(dependency.cluster_access.outputs.kubernetes_client_configuration.ca_certificate)}
EOT
}
EOF
}

inputs = {
  hcloud_token = get_env("HETZNER_API_TOKEN")
  network_id   = tostring(dependency.network.outputs.id)
}
