terraform {
  source = "${local.modules_url}/${local.module_dir}?tag=${local.module_version}"
}

locals {
  common_settings = read_terragrunt_config("${get_repo_root()}/root.hcl")
  modules_url     = local.common_settings.locals.private_modules_base_url
  module_dir      = "litellm/virtual_key"
  module_version  = "0.1.0"
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "vault" {
  address = "${get_env("VAULT_ADDR")}"
  token   = "${get_env("VAULT_TOKEN")}"
}

data "vault_kv_secret_v2" "master_key" {
  mount = "platform"
  name  = "litellm"
}

provider "litellm" {
  api_base = "https://litellm.from-the-lamp.work"
  api_key  = data.vault_kv_secret_v2.master_key.data["master_key"]
}
EOF
}
