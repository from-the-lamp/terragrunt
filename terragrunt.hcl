locals {
  gitlab_base_url = "gitlab.com"
  gitlab_token = get_env("TF_HTTP_PASSWORD")
  infra_helm_repo_url = "https://gitlab.com/api/v4/projects/40582099/packages/helm/stable"
  k3s_cluster_version = "v1.25.11+k3s1"
  infra_repo_id = "40541314"
  private_modules_path = "from-the-lamp/infra/terraform/modules"
  private_modules_base_url = "git::https://gitlab-ci-token:${local.gitlab_token}@${local.gitlab_base_url}/${local.private_modules_path}"
  infra_project_id = "40541314"
  admin_ssh_pub = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILtNvLcjDTFxc/v03D93cyeEa77jxNC/u2DfqM9gn0k6"
  helm_repo_user = "gitlab-ci-token"
  helm_repo_pass = get_env("TF_HTTP_PASSWORD")
  openid_client_id_argocd = "2fd7eebea2c98fcc945b386fef203dfdc21b066f53cd23307baa9844264ff32e"
}

remote_state {
  backend = "http"
  generate = {
    path = "backend.generated.tf"
    if_exists = "overwrite"
  }
  config = {
    address = "https://${local.gitlab_base_url}/api/v4/projects/${local.infra_repo_id}/terraform/state/${replace(path_relative_to_include(), "/", "_")}"
    lock_address = "https://${local.gitlab_base_url}/api/v4/projects/${local.infra_repo_id}/terraform/state/${replace(path_relative_to_include(), "/", "_")}/lock"
    unlock_address = "https://${local.gitlab_base_url}/api/v4/projects/${local.infra_repo_id}/terraform/state/${replace(path_relative_to_include(), "/", "_")}/lock"
    lock_method = "POST"
    unlock_method = "DELETE"
    retry_wait_min = 5
  }
}
