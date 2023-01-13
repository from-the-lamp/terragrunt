include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/helm.hcl"
}

inputs = {
  helm_external_repo    = true
  helm_values_file      = "values.yml"
  helm_repo_url         = "https://charts.gitlab.io"
  helm_chart_name       = "gitlab-runner"
  helm_chart_version    = "0.47.1"
  k8s_namespace         = "infra"
  helm_addition_setting = {
    runnerRegistrationToken = "${get_env("TF_VAR_runnerRegistrationToken")}"
  }  
}
