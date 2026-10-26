terraform {
  source = "${local.modules_url}/talos/access?tag=1.0.0"
}

locals {
  common_settings  = read_terragrunt_config("${get_repo_root()}/root.hcl")
  modules_url      = local.common_settings.locals.private_modules_base_url
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  cluster_name     = local.environment_vars.locals.cluster_name
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "talos" {}
EOF
}

inputs = {
  cluster_name = local.cluster_name
}
