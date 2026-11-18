include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_repo_root()}/_modules/oneuptime/workspace_notification_rule"
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
  slack_channel_name = "alerting"
}
