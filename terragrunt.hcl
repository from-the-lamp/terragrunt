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

locals {
  gitlab_base_url = "gitlab.com"
  gitlab_token = get_env("TF_HTTP_PASSWORD")
  infra_variables_file = "TF_VAR_FILE_INFRA"
  infra_helm_repo_id = "40582099"
  infra_helm_repo_url = "https://${local.gitlab_base_url}/api/v4/projects/${local.infra_helm_repo_id}/packages/helm/stable"
  k3s_cluster_version = "v1.25.11+k3s1"
  infra_repo_id = "40541314"
  private_modules_path = "from-the-lamp/infra/terraform/modules"
  private_modules_base_url = "git::https://gitlab-ci-token:${local.gitlab_token}@${local.gitlab_base_url}/${local.private_modules_path}"
  local_modules_base_path = "${get_repo_root()}/_modules//"
  infra_project_id = "40541314"
  admin_ssh_pub = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILtNvLcjDTFxc/v03D93cyeEa77jxNC/u2DfqM9gn0k6"
  helm_repo_user = "gitlab-ci-token"
  helm_repo_pass = get_env("TF_HTTP_PASSWORD")
  vault_base_url = "vault.from-the-lamp.com"
  openid_client_id_vault = "6c818bd896fabe3395fc48379925a2e1fa0432b821312228585886fb9e244f64"
  openid_client_id_kiali = "34abbfae423ab9f382c578bd1953ea5b68dd055af9cc349dbb748c5def2cb1bd"
  openid_client_id_grafana = "913608a80a8f71ed9a73d9baa2662033cc570a0f473b29e10c7dd34ace8a0524"
  openid_client_id_argocd = "2fd7eebea2c98fcc945b386fef203dfdc21b066f53cd23307baa9844264ff32e"
  openid_client_id_oauth2_proxy = "5703099d64bb707c5a08fd269065057ff6f8b16198241fbdc3fc04119875e0b4"
  openid_client_id_pgadmin4 = "8a4514b7270384f4626b70fc3ed039fe1eecacc80d94082d45ebcab197bc29a5"
}
