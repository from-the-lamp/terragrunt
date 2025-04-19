include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "common" {
  path = "${get_repo_root()}/_common/oracle/identity_dynamic_group.hcl"
}

inputs = {
  name = "${basename(dirname(get_terragrunt_dir()))}-ccm"
}
