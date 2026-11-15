include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "common" {
  path = "${get_repo_root()}/_common/gitlab/webhook.hcl"
}

# FTL-176: ingest-gitlab's /webhook/gitlab needs the project to already
# exist - same reasoning as every sa/developer unit's own dependency on
# ../project.
dependency "project" {
  config_path                             = "../project"
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    id                  = "0"
    path_with_namespace = "from-the-lamp/infra/terragrunt"
  }
}

inputs = {
  project           = dependency.project.outputs.path_with_namespace
  url               = "https://gitlab-webhook.from-the-lamp.com/webhook/gitlab"
  vault_secret_path = "gitlab"
  vault_property    = "from-the-lamp.webhook_secret"
}
