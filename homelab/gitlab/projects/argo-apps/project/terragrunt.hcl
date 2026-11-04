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
  name           = "argo-apps"
}
