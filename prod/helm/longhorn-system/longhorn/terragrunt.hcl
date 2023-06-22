include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/k8s/helm.hcl"
}

inputs = {
  helm_external_repo    = true
  helm_chart_name       = "longhorn"
  helm_repo_url         = "https://charts.longhorn.io"
  helm_chart_version    = "1.4.0"
}
