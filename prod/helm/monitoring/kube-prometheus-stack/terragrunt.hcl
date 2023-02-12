include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/helm.hcl"
}

dependency "get_infra_variables" {
  config_path = "../../../gitlab/get_infra_variables"
  mock_outputs_allowed_terraform_commands = ["apply" ,"plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    "map_variables.grafana_admin_pass" = "fake-pass"
  }
}

inputs = {
  helm_external_repo    = true
  helm_virtual_service  = true
  force_update          = false
  recreate_pods         = false
  helm_values_file      = "values.yml"
  helm_chart_name       = "kube-prometheus-stack"
  helm_repo_url         = "https://prometheus-community.github.io/helm-charts"
  helm_chart_version    = "43.2.1"
  helm_virtual_service  = true
  helm_addition_setting = {
    "destination.name"      = "kube-prometheus-stack-grafana"
    "destination.port"      = "80"
    "grafana.adminPassword" = dependency.get_infra_variables.outputs.map_variables.grafana_admin_pass
  }
}
