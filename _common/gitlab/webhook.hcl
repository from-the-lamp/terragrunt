terraform {
  source = "${local.modules_url}/${local.module_dir}?tag=${local.module_version}"
}

locals {
  common_settings = read_terragrunt_config("${get_repo_root()}/root.hcl")
  modules_url     = local.common_settings.locals.private_modules_base_url
  module_dir      = "gitlab/webhook"
  module_version  = "1.0.1"
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  # gitlab provider: same reasoning as _common/gitlab/project.hcl - reuses
  # root.hcl's own gitlab_token (GITLAB_API_TOKEN), a real Owner-level PAT.
  # vault provider: same pattern as _common/litellm/virtual_key.hcl - reads
  # the webhook's shared token from Vault instead of a plain terragrunt
  # input (VAULT_ADDR/VAULT_TOKEN from `task vault:login`).
  contents = <<EOF
provider "gitlab" {
  token = "${local.common_settings.locals.gitlab_token}"
}

provider "vault" {
  address = "${get_env("VAULT_ADDR")}"
  token   = "${get_env("VAULT_TOKEN")}"
}
EOF
}
