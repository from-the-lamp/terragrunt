include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/k8s/helm.hcl"
}

inputs = {
  helm_external_repo    = true
  helm_repo_url         = "https://kiali.org/helm-charts"
  helm_chart_name       = "kiali-operator"
  helm_chart_version    = "1.61.0"
}
