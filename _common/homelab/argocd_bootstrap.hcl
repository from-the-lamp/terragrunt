# Bare-metal counterpart to _common/hetzner/argocd_bootstrap.hcl - same
# shared module (_modules/hetzner/argocd_bootstrap, fully generic despite
# the directory name - nothing Hetzner-specific in main.tf), just no
# load_balancer dependency: the provider talks to the node's own static IP
# directly.
terraform {
  source = "${get_repo_root()}/_modules/hetzner/argocd_bootstrap"
}

locals {
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  node_1_ip        = local.environment_vars.locals.node_1_ip
}

dependency "cluster_access" {
  config_path                             = "${get_repo_root()}/homelab/talos/access"
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

# Ordering only: the Application CRD is installed by the argocd Helm
# release itself, so it must exist before this unit can create an
# Application custom resource.
dependency "argocd" {
  config_path                             = "${get_repo_root()}/homelab/helm/argocd/argocd"
  mock_outputs_allowed_terraform_commands = ["plan", "apply", "validate", "output", "init", "destroy"]
  skip_outputs                            = true
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "kubernetes" {
  host = "https://${local.node_1_ip}:6443"
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
  repo_url = "https://gitlab.com/from-the-lamp/infra/argo-apps.git"
}
