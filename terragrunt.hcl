locals {
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env = local.environment_vars.locals.environment
}

remote_state {
  backend = "http"
  config = {
    address        = "https://gitlab.com/api/v4/projects/40541314/terraform/state/${local.env}-${basename(get_terragrunt_dir())}"
    lock_address   = "https://gitlab.com/api/v4/projects/40541314/terraform/state/${local.env}-${basename(get_terragrunt_dir())}/lock"
    unlock_address = "https://gitlab.com/api/v4/projects/40541314/terraform/state/${local.env}-${basename(get_terragrunt_dir())}/lock"
    username       = "gitlab-ci-token"
    lock_method    = "POST"
    unlock_method  = "DELETE"
  }
}

generate "terraform" {
  path      = "terraform_http_backend.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
    terraform {
      backend "http" {}
    }
  EOF
}
