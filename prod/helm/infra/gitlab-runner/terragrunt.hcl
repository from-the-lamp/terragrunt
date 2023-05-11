include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/helm.hcl"
}

locals {
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env = local.environment_vars.locals.environment
}

dependency "get_infra_variables" {
  config_path = "${get_repo_root()}/${local.env}/gitlab/get_infra_variables"
  mock_outputs_allowed_terraform_commands = ["apply" ,"plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    "map_variables.runnerRegistrationToken" = "fake-token"
  }
}

inputs = {
  helm_external_repo    = true
  helm_repo_url         = "https://charts.gitlab.io"
  helm_chart_name       = "gitlab-runner"
  helm_chart_version    = "0.47.1"
  helm_addition_setting = {
    runnerRegistrationToken = dependency.get_infra_variables.outputs.map_variables.runnerRegistrationToken
  }  
}
