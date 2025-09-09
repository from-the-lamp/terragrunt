include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "common" {
  path = "${get_repo_root()}/_common/kubernetes/helm.hcl"
}

inputs = {
  helm_chart_name    = "lamp-external-secrets"
  helm_chart_version = "0.0.1"
}
