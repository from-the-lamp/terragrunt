include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/helm.hcl"
}

inputs = {
  helm_external_repo    = true
  helm_values_file      = "values.yml"
  helm_chart_name       = "longhorn"
  helm_repo_url         = "https://charts.longhorn.io"
  helm_chart_version    = "1.4.0"
  k8s_namespace         = "longhorn-system"
}
