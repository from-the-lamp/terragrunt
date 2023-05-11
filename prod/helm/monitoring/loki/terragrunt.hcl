include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/helm.hcl"
}

inputs = {
  helm_external_repo    = true
  helm_repo_url         = "https://grafana.github.io/helm-charts"
  helm_chart_name       = "loki-stack"
  helm_chart_version    = "2.9.10"
}
