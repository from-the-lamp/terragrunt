include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/tools/random_password.hcl"
}

inputs = {
  password_length  = 50
  password_special = false
}
