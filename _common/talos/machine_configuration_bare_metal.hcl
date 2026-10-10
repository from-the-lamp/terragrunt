# Bare-metal counterpart to machine_configuration.hcl (that one's
# config_patches assume hcloud-cloud-controller-manager and a shared private
# network CIDR - neither exists here). Unlike the Hetzner version, this
# deliberately does NOT set config_patches itself: Hetzner's 3 nodes all get
# an identical patch because each node's own IP/hostname comes from DHCP +
# Hetzner's metadata service at boot, but homelab nodes use static network
# config baked directly into the machine config - that's inherently
# per-node, so each node's own terragrunt.hcl (homelab/talos/machine_config/
# node-N) supplies its own config_patches instead of sharing one here.
terraform {
  source = "${get_repo_root()}/_modules/talos/machine_configuration"
}

locals {
  environment_vars   = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  cluster_name       = local.environment_vars.locals.cluster_name
  talos_version      = local.environment_vars.locals.talos_version
  kubernetes_version = local.environment_vars.locals.kubernetes_version
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "talos" {}
EOF
}

inputs = {
  cluster_name       = local.cluster_name
  machine_type       = "controlplane"
  talos_version      = local.talos_version
  kubernetes_version = local.kubernetes_version
}
