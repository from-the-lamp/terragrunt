terraform {
  source = "${get_repo_root()}/_modules/hetzner/network"
}

locals {
  environment_vars     = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  cluster_name         = local.environment_vars.locals.cluster_name
  hetzner_network_zone = local.environment_vars.locals.hetzner_network_zone
  private_network_cidr = local.environment_vars.locals.private_network_cidr
  private_subnet_cidr  = local.environment_vars.locals.private_subnet_cidr
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
  name     = local.cluster_name
  ip_range = local.private_network_cidr
  subnets = {
    nodes = {
      ip_range     = local.private_subnet_cidr
      network_zone = local.hetzner_network_zone
    }
  }
}
