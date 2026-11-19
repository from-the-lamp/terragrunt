include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_repo_root()}/_modules/oneuptime/ai_rule"
}

locals {
  common_settings = read_terragrunt_config("${get_repo_root()}/root.hcl")
  modules_url     = local.common_settings.locals.private_modules_base_url
  module_dir      = "oneuptime/ai_rule"
  module_version  = "0.3.0"
}

include "oneuptime_provider" {
  path = "${get_repo_root()}/_common/oneuptime/provider.hcl"
}

dependency "gitlab_mcp" {
  config_path                             = "${get_repo_root()}/homelab/oneuptime/gitlab-mcp-server"
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
  mock_outputs = {
    id = "00000000-0000-0000-0000-000000000000"
  }
}

inputs = {
  name                = "Alert investigation and fix"
  description         = "Investigates every alert and opens a fix merge request in a connected repository when the cause is in platform code."
  trigger_entity_type = "Alert"

  title_pattern = "^(?!.*litellm)"

  execution_mode             = "Suggest"
  investigates               = true
  only_if_open_after_minutes = 30
  fixes                      = true

  open_code_fix_pull_requests  = true
  open_telemetry_pull_requests = false

  external_mcp_server_ids = [dependency.gitlab_mcp.outputs.id]

  ai_context = <<-EOT
    Алерты здесь - warning-сигналы Alertmanager, например
    KubeContainerOOMKilled, а не подтверждённые инциденты. Единичный OOM с
    успешным восстановлением не требует правки, если он не повторяется.
  EOT
}
