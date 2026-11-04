# This project already exists on GitLab - terraform import both resources
# (gitlab_project.this, gitlab_branch_protection.default) before ever running
# apply here. Inputs below are a best-guess at current reality, not a
# confirmed read of it - after import, reconcile the plan diff against the
# project's actual real settings first.

include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "common" {
  path = "${get_repo_root()}/_common/gitlab/project.hcl"
}

inputs = {
  namespace_path = "from-the-lamp/infra"
  # Local dir is "modules" / "terraform-modules" depending on which repo
  # table you read - the real GitLab project path is "terraform-modules"
  # (confirmed via this checkout's own `git remote get-url origin`, unlike
  # the terragrunt one below which had a stale remote).
  name = "terraform-modules"
}
