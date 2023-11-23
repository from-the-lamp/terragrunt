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
  versions = read_terragrunt_config("${get_repo_root()}/_common/versions.hcl")
  istio_system_version = local.versions.locals.istio_system
}

dependency "istio" {
  config_path = "../istio"
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "output", "init", "destroy"]
  skip_outputs = true
}

inputs = {
  project = "infra"
  apps = [
    {
      helm_repo_url = "https://istio-release.storage.googleapis.com/charts"
      helm_chart_version = local.istio_system_version
    }
  ]
}
