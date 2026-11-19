include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "common" {
  path = "${get_repo_root()}/_common/tools/random_password.hcl"
}

inputs = {
  password_length  = 48
  password_special = false
}
