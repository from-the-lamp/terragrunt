include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/helm.hcl"
}

dependency "ististio-ingressgateway" {
  config_path  = "../istio-ingressgateway"
  skip_outputs = true
}

inputs = {
  helm_internal_repo = true
  helm_chart_name    = "istio-gateway"
  helm_chart_version = "0.0.2"
}
