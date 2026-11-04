include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "common" {
  path = "${get_repo_root()}/_common/gitlab/group_owner_bot.hcl"
}

# Owner on the from-the-lamp group, not scoped to one project - this is the
# bot whose own rotating token backs GITLAB_API_TOKEN (the gitlab provider's
# auth for every unit under homelab/gitlab/**, including re-applying this
# very unit to rotate itself). Separate identity from kelos-bot-* (those stay
# Developer, project-scoped, per repo) - see the module's README for why
# this isn't just a bigger input to that module.
dependency "project" {
  config_path                             = "../../projects/terragrunt/project"
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    path_with_namespace = "from-the-lamp/infra/terragrunt"
  }
}

inputs = {
  group              = "from-the-lamp"
  bot_name           = "terragrunt-automation"
  rotate_before_days = 3
  expiration_days    = 10

  # Writes the token straight into this project's own CI/CD variable on
  # every apply (including rotations) - plan and apply both just read
  # GITLAB_API_TOKEN normally, no fetch step, no Vault involved.
  ci_variable = {
    project = dependency.project.outputs.path_with_namespace
    key     = "GITLAB_API_TOKEN"
  }
}
