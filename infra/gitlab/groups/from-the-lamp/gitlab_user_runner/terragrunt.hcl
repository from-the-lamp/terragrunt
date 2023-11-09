include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/gitlab/gitlab_user_runner.hcl"
}

inputs = {
  group_id = "59383214"
  tag_list = ["k8s-arm"]
}
