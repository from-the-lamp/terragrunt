include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/k8s/helm.hcl"
}

dependency "istio" {
  config_path  = "../../istio-system/istio"
  skip_outputs = true
}

dependency "istiod" {
  config_path  = "../../istio-system/istiod"
  skip_outputs = true
}

inputs = {
  helm_external_repo = true
  helm_values_file   = "values.yml"
  helm_chart_name    = "gateway"
  helm_repo_url      = "https://istio-release.storage.googleapis.com/charts"
  helm_chart_version = "1.16.1"
}

