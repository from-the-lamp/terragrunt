include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/gitlab/get_projects_list.hcl"
}

inputs = {
  gitlab_group_full_path = ""
}
