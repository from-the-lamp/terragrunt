include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/helm.hcl"
}

inputs = {
  helm_local_repo       = true
  k8s_namespace         = "infra"
  helm_addition_setting = {
    "base64DockerConfigs.gitlab-docker-registry" = "${get_env("TF_VAR_gitlab_pull_secret")}"
  }
}
