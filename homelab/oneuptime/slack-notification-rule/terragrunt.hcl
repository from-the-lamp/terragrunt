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
  name        = "Critical incidents to Slack"
  description = "Posts critical-severity incidents into the connected Slack workspace, independent of the Kelos/alert-notifier pipeline."

  slack_channel_name = "alerting"
  updates_to_post    = ["ResolvedAndReopened", "SeverityChanges"]
}
