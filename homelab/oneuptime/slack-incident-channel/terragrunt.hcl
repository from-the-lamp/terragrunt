include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${local.modules_url}/${local.module_dir}?tag=${local.module_version}"
}

locals {
  common_settings = read_terragrunt_config("${get_repo_root()}/root.hcl")
  modules_url     = local.common_settings.locals.private_modules_base_url
  module_dir      = "oneuptime/workspace_notification_rule"
  module_version  = "0.1.0"
}

include "oneuptime_provider" {
  path = "${get_repo_root()}/_common/oneuptime/provider.hcl"
}

inputs = {
  name        = "Channel per critical incident"
  description = "Creates a Slack channel for every critical incident, posts its whole history there and archives it on resolve."

  create_channel_per_incident = true
  invite_user_ids             = ["a28b0313-2156-4b65-87d7-124099dab919"]
}
