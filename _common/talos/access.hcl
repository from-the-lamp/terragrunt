terraform {
  source = "${get_repo_root()}/_modules/talos/access"
}

locals {
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
