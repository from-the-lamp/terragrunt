locals {
  gitlab_base_url = "gitlab.com"
  # Deliberately NOT TF_HTTP_PASSWORD (the state backend's own auth, read
  # directly by Terraform's http backend from the OS environment - in CI
  # that becomes gitlab-ci-token/$CI_JOB_TOKEN, scoped to this project only,
  # set in .gitlab-ci.yml, no CI/CD variable needed). This one backs the
  # `gitlab` provider (creates Service Accounts/projects group-wide under
  # from-the-lamp) and the cross-project OCI pulls below (helm charts,
  # terraform modules, published by OTHER projects) - both need a real
  # Owner-level credential a job token can never provide, so they stay on
  # a separately-named, manually-configured secret.
  gitlab_token             = get_env("GITLAB_API_TOKEN")
  k3s_cluster_version      = "v1.25.11+k3s1"
  infra_repo_id            = "40541314"
  private_modules_base_url = "oci://registry.gitlab.com/from-the-lamp/infra/terraform-modules"
  infra_project_id         = "40541314"
  admin_ssh_pub            = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILtNvLcjDTFxc/v03D93cyeEa77jxNC/u2DfqM9gn0k6"
  helm_repo_user           = "gitlab-ci-token"
  helm_repo_pass           = get_env("GITLAB_API_TOKEN")
}

remote_state {
  backend = "http"
  generate = {
    path      = "backend.generated.tf"
    if_exists = "overwrite"
  }
  config = {
    address        = "https://${local.gitlab_base_url}/api/v4/projects/${local.infra_repo_id}/terraform/state/${replace(path_relative_to_include(), "/", "_")}"
    lock_address   = "https://${local.gitlab_base_url}/api/v4/projects/${local.infra_repo_id}/terraform/state/${replace(path_relative_to_include(), "/", "_")}/lock"
    unlock_address = "https://${local.gitlab_base_url}/api/v4/projects/${local.infra_repo_id}/terraform/state/${replace(path_relative_to_include(), "/", "_")}/lock"
    lock_method    = "POST"
    unlock_method  = "DELETE"
    retry_wait_min = 5
  }
}
