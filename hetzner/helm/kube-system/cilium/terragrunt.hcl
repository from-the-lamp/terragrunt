include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "common" {
  path = "${get_repo_root()}/_common/hetzner/helm.hcl"
}

inputs = {
  helm_chart_name    = "lamp-cilium"
  helm_chart_version = "0.1.1"
}
