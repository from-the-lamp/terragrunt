include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/helm.hcl"
}

dependency "gitlab_vars" {
  config_path = "../../../gitlab/variables"
  mock_outputs_allowed_terraform_commands = ["apply" ,"plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    "map_variables.runnerRegistrationToken" = "fake-token"
  }
}

inputs = {
  helm_external_repo    = true
  helm_values_file      = "values.yml"
  helm_repo_url         = "https://charts.gitlab.io"
  helm_chart_name       = "gitlab-runner"
  helm_chart_version    = "0.47.1"
  helm_addition_setting = {
    runnerRegistrationToken = dependency.gitlab_vars.outputs.map_variables.runnerRegistrationToken
  }  
}
