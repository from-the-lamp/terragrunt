include "root" {
  path = find_in_parent_folders()
  expose = true
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/helm.hcl"
}

dependency "kube-prometheus-stack" {
  config_path  = "../../monitoring/kube-prometheus-stack"
  skip_outputs = true
}

dependency "kiali-operator" {
  config_path  = "../kiali-operator"
  skip_outputs = true
}

inputs = {
  helm_internal_repo    = true
  helm_virtual_service  = true
  helm_chart_name       = "kiali-cr"
  helm_chart_version    = "0.0.3"
  helm_addition_setting = {
    "gateway.port" = "20001"
  }
}
