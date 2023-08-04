include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/k8s/helm.hcl"
}

locals {
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env              = local.environment_vars.locals.environment
}

dependency "istio" {
  config_path  = "../../istio-system/istio"
  skip_outputs = true
}

dependency "istiod" {
  config_path  = "../../istio-system/istiod"
  skip_outputs = true
}


dependency "allow_https_from_all" {
  config_path = "${get_repo_root()}/${local.env}/oracle/nsg/allow_https_from_all"
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    id = "fake-id"
  }
}

inputs = {
  helm_external_repo    = true
  helm_chart_name       = "gateway"
  helm_repo_url         = "https://istio-release.storage.googleapis.com/charts"
  helm_chart_version    = "1.16.1"
  helm_addition_setting = {
    "service.annotations.oci\\.oraclecloud\\.com/oci-network-security-groups" = dependency.allow_https_from_all.outputs.id
  }
}
