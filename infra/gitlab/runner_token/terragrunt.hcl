include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "common" {
  path = "${get_repo_root()}/_common/gitlab/gitlab_user_runner.hcl"
}

inputs = {
  group_id = "59383214"
  tag_list = ["micro-arm64"]
}
