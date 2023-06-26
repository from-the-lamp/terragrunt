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

dependency "namespace" {
  config_path = "../namespace"
  mock_outputs_allowed_terraform_commands = ["apply", "plan", "validate", "output", "init", "destroy"]
  skip_outputs = true
}

dependency "gitlab_runner_token" {
  config_path = "../gitlab_runner_token"
  mock_outputs_allowed_terraform_commands = ["apply" ,"plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    "runners_token" = "fake-token"
  }
}

inputs = {
  helm_external_repo    = true
  helm_values_file      = "values.yml"
  helm_chart_name       = "gitlab-runner"
  helm_repo_url         = "https://charts.gitlab.io"
  helm_chart_version    = "0.54.0"
  helm_addition_setting = {
    runnerRegistrationToken = dependency.gitlab_runner_token.outputs.runners_token
  }
}
