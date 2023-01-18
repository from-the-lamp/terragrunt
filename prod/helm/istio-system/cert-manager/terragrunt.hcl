include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/helm.hcl"
}

inputs = {
  helm_external_repo    = true
  helm_values_file      = "values.yml"
  helm_repo_url         = "https://charts.jetstack.io"
  helm_chart_name       = "cert-manager"
  helm_chart_version    = "1.9.1"
}
