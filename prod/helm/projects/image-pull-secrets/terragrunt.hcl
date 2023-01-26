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
    "map_variables.gitlab_docker_registry_secret" = "fake-secret"
  }
}

inputs = {
  helm_internal_repo    = true
  helm_chart_name       = "image-pull-secrets"
  helm_chart_version    = "0.0.1"
  helm_addition_setting = {
    "base64DockerConfigs.gitlab-docker-registry" = dependency.gitlab_vars.outputs.map_variables.gitlab_docker_registry_secret
  }
}
