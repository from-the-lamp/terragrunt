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
    "destination.name" = "kiali"
    "destination.port" = "20001"
    "gateway.enabled"  = true
    "gateway.external" = true
    "gateway.hosts[0]" = "${basename(get_terragrunt_dir())}.${local.infra_zone}"
    "grafana.url"      = "https://grafana.${local.infra_zone}"
  }
}
