include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_repo_root()}/_modules/oneuptime/project_settings"
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "vault" {
  address = "${get_env("VAULT_ADDR")}"
  token   = "${get_env("VAULT_TOKEN")}"
}

data "vault_kv_secret_v2" "oneuptime_creds" {
  mount = "platform"
  name  = "oneuptime"
}

provider "oneuptime" {
  oneuptime_url = "https://oneuptime.from-the-lamp.work"
  api_key       = data.vault_kv_secret_v2.oneuptime_creds.data["api-key"]
}
EOF
}

inputs = {
  project_id = "20d35059-271e-4472-9849-d9ca99582870"
  name       = "from-the-lamp"
}
