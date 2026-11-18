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
  name        = "Channel per critical incident"
  description = "Creates a Slack channel for every critical incident, posts its whole history there and archives it on resolve."

  create_channel_per_incident = true
  invite_user_ids             = ["a28b0313-2156-4b65-87d7-124099dab919"]
}
