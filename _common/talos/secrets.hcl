terraform {
  source = "${get_repo_root()}/_modules/talos/secrets"
}

locals {
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  talos_version    = local.environment_vars.locals.talos_version
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "talos" {}
EOF
}

inputs = {
  talos_version = local.talos_version
}
