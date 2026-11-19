include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_repo_root()}/_modules/oneuptime/external_mcp_server"
}

locals {
  common_settings = read_terragrunt_config("${get_repo_root()}/root.hcl")
  modules_url     = local.common_settings.locals.private_modules_base_url
  module_dir      = "oneuptime/external_mcp_server"
  module_version  = "0.2.0"
}

include "oneuptime_provider" {
  path = "${get_repo_root()}/_common/oneuptime/provider.hcl"
}

dependency "client_secret" {
  config_path                             = "${get_repo_root()}/homelab/toolhive/oneuptime-client/password"
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
  mock_outputs = {
    password = "fake-client-secret"
  }
}

inputs = {
  name        = "from-the-lamp platform tools (read-only)"
  description = "Read-only tools for the homelab cluster: Kubernetes objects, events and pod logs, VictoriaMetrics metrics and Loki logs through Grafana, Argo CD application state, GitLab repository contents."

  url       = "http://vmcp-vmcp-mcp-tools-oneuptime.toolhive.svc.cluster.local:4483/mcp"
  auth_type = "OAuthClientCredentials"

  oauth_token_url     = "https://mcp.from-the-lamp.work/dex/token"
  oauth_client_id     = "oneuptime-toolhive"
  oauth_client_secret = dependency.client_secret.outputs.password
}
