include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/argocd/application_set.hcl"
}

locals {
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env = local.environment_vars.locals.environment
  common_settings = read_terragrunt_config("${get_repo_root()}/terragrunt.hcl")
}

dependency "oci-cloud-controller-manager" {
  config_path = "${get_repo_root()}/${local.env}/helm/kube-system/oci-cloud-controller-manager"
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "output", "init", "destroy"]
  skip_outputs = true
}

inputs = {
  project = "infra"
  apps = [
    {
      helm_repo_url = "https://istio-release.storage.googleapis.com/charts"
      helm_chart_name = "base"
      helm_chart_version = "1.20.0"
    }
  ]
}
