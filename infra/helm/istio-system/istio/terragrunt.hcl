include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/k8s/helm.hcl"
}

locals {
  environment_vars     = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env                  = local.environment_vars.locals.environment
  common_settings      = read_terragrunt_config("${get_repo_root()}/terragrunt.hcl")
  versions             = read_terragrunt_config("${get_repo_root()}/_common/versions.hcl")
  istio_system_version = local.versions.locals.istio_system
}

dependency "oci-cloud-controller-manager" {
  config_path = "../../kube-system/oci-cloud-controller-manager"
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "output", "init", "destroy"]
  skip_outputs = true
}

inputs = {
  helm_repo_url      = "https://istio-release.storage.googleapis.com/charts"
  helm_chart_name    = "base"
  helm_chart_version = local.istio_system_version
}
