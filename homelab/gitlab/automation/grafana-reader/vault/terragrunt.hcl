include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "common" {
  path = "${get_repo_root()}/_common/vault/secrets_managed.hcl"
}

# platform/gitlab already holds oauth_client_id/oauth_client_secret
# (Grafana's own GitLab OAuth login) and notifications_slack_token,
# hand-written - merge = true so this unit only ever touches its own
# from-the-lamp.grafana-reader key and leaves those alone. Same key format
# the datasource-gitlab-token ExternalSecret in
# argo-apps/apps/homelab/platform/grafana already reads
# (remoteRef.property: "from-the-lamp.grafana-reader").
dependency "bot" {
  config_path                             = ".."
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    token = "fake-token-grafana-reader"
  }
}

inputs = {
  path        = "platform"
  secret_path = "gitlab"
  merge       = true
  data = {
    "from-the-lamp.grafana-reader" = dependency.bot.outputs.token
  }
}
