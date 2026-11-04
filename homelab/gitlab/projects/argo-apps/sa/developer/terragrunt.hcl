include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "common" {
  path = "${get_repo_root()}/_common/gitlab/service_account.hcl"
}

# Forces this unit to wait for ../project to actually exist before trying to
# add the bot as a member of it - without this edge, terragrunt has no way
# to know the two are related (project was just a literal string here
# before) and runs them concurrently, which 404s on a brand-new project
# that hasn't finished being created yet. Harmless for an already-existing
# project (the common case here), required for a new one.
dependency "project" {
  config_path                             = "../../project"
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    id                  = "0"
    path_with_namespace = "from-the-lamp/infra/argo-apps"
  }
}

inputs = {
  group              = "from-the-lamp"
  project            = dependency.project.outputs.path_with_namespace
  bot_name           = "kelos-bot-argo-apps"
  rotate_before_days = 3
  expiration_days    = 10
}
