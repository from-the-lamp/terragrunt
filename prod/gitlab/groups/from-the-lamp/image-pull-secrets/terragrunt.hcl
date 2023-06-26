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

dependency "gitlab_vars" {
  config_path = "${get_repo_root()}/${local.env}/gitlab/get_infra_variables"
  mock_outputs_allowed_terraform_commands = ["apply" ,"plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    "map_variables.gitlab_docker_registry_token" = "fake-secret"
  }
}

inputs = {
  helm_internal_repo    = true
  helm_chart_name       = "image-pull-secret"
  helm_chart_version    = "0.0.1"
  helm_addition_setting = {
    token = dependency.gitlab_vars.outputs.map_variables.gitlab_docker_registry_token
  }
}
