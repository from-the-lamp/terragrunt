include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/oracle/identity_dynamic_group.hcl"
}

inputs = {
  name = "${basename(dirname(get_terragrunt_dir()))}-ccm"
}
