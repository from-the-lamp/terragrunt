include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/gitlab/add_variables.hcl"
}

inputs = {
  vars = {
    "K8S_NAMESPACE" = {
      value     = "${basename(dirname(get_terragrunt_dir()))}"
      protected = false
      masked    = false
    },
  }
}
