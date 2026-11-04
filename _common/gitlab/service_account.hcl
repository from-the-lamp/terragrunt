terraform {
  source = "${local.modules_url}/${local.module_dir}?tag=${local.module_version}"
}

locals {
  common_settings = read_terragrunt_config("${get_repo_root()}/root.hcl")
  modules_url     = local.common_settings.locals.private_modules_base_url
  module_dir      = "gitlab/service_account"
  module_version  = "1.0.0"
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  # Reuses root.hcl's own gitlab_token (GITLAB_API_TOKEN) - a real
  # Owner-level PAT, required for this provider's group-wide Service
  # Account calls. Deliberately NOT TF_HTTP_PASSWORD: that one is the state
  # backend's own auth and in CI resolves to gitlab-ci-token/$CI_JOB_TOKEN,
  # scoped to this project only - nowhere near enough for this.
  contents = <<EOF
provider "gitlab" {
  token = "${local.common_settings.locals.gitlab_token}"
}
EOF
}
