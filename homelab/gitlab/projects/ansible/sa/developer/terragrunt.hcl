include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "common" {
  path = "${get_repo_root()}/_common/gitlab/service_account.hcl"
}

# See blog/sa/developer's version of this unit for why this dependency
# exists (forces waiting on the project actually existing) - ansible is in
# the same situation blog was: new, not pre-existing.
dependency "project" {
  config_path                             = "../../project"
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    id                  = "0"
    path_with_namespace = "from-the-lamp/infra/ansible"
  }
}

inputs = {
  group              = "from-the-lamp"
  project            = dependency.project.outputs.path_with_namespace
  bot_name           = "kelos-bot-ansible"
  rotate_before_days = 3
  expiration_days    = 10
}
