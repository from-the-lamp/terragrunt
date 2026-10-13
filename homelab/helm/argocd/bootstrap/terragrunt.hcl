include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "common" {
  path = "${get_repo_root()}/_common/homelab/argocd_bootstrap.hcl"
}

inputs = {
  name = "homelab-projects"
  path = "projects"
}
