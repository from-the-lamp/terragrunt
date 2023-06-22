locals {
  gitlab_token             = get_env("TF_HTTP_PASSWORD")
  private_modules_base_url = "git::https://gitlab-ci-token:${local.gitlab_token}@gitlab.com/from-the-lamp/infra/terraform/modules"
  local_modules_base_path  = "${get_repo_root()}/_modules//"
  infra_project_id         = "40541314"
}
