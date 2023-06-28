include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/k8s/helm.hcl"
}

locals {
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  infra_zone = local.environment_vars.locals.infra_zone
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
    "grafana.url"      = "https://grafana.${local.infra_zone}"
  }
  helm_virtual_service          = true
  helm_virtual_service_host     = "kiali.${local.infra_zone}"
  helm_virtual_service_svc_host = "kiali"
  helm_virtual_service_svc_port = 20001
  helm_virtual_service_setting  = {
    external = true
  } 
}
