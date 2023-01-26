include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/gitlab-variables.hcl"
}

inputs = {
  gitlab_project_variable = "TF_VAR_FILE_PROD"
}
