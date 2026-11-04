terraform {
  source = "${local.modules_url}/${local.module_dir}?tag=${local.module_version}"
}

locals {
  common_settings = read_terragrunt_config("${get_repo_root()}/root.hcl")
  modules_url     = local.common_settings.locals.private_modules_base_url
  module_dir      = "gitlab/group_owner_bot"
  module_version  = "1.1.0"
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  # Same reasoning as _common/gitlab/service_account.hcl - reuses root.hcl's
  # own gitlab_token (GITLAB_API_TOKEN). The very first apply of this unit
  # needs that to already be a human Owner-level PAT (nothing can grant a
  # service account group Owner without an already-Owner-level caller) -
  # every apply after that can use this very bot's own rotated token instead.
  contents = <<EOF
provider "gitlab" {
  token = "${local.common_settings.locals.gitlab_token}"
}
EOF
}
