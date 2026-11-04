terraform {
  source = "${local.modules_url}/${local.module_dir}?tag=${local.module_version}"
}

locals {
  common_settings = read_terragrunt_config("${get_repo_root()}/root.hcl")
  modules_url     = local.common_settings.locals.private_modules_base_url
  module_dir      = "gitlab/project"
  module_version  = "1.0.1"
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  # Same reasoning as _common/gitlab/service_account.hcl - reuses root.hcl's own
  # gitlab_token (TF_HTTP_PASSWORD), already Owner-scoped for the state
  # backend's own API access.
  contents = <<EOF
provider "gitlab" {
  token = "${local.common_settings.locals.gitlab_token}"
}
EOF
}

# Explicit on purpose - these are the module's own defaults too, but spelled
# out here so the actual policy for every from-the-lamp project is visible
# in one place without reading the module source. A leaf unit only needs to
# override a key here if that one project is a real exception (see
# helm-charts' visibility_level history before this file existed).
inputs = {
  visibility_level   = "public"
  default_branch     = "main"
  merge_method       = "merge"
  push_access_level  = "maintainer"
  merge_access_level = "maintainer"
  allow_force_push   = false

  # OCI/container registry cleanup - relevant to helm-charts, docker-images,
  # terraform-modules (all push OCI artifacts through the same registry
  # backend); inert but harmless for repos that don't.
  container_expiration_policy_enabled           = true
  container_expiration_policy_cadence           = "1d"
  container_expiration_policy_keep_n            = 1
  container_expiration_policy_older_than        = "90d"
  container_expiration_policy_name_regex_delete = ".*"
  container_expiration_policy_name_regex_keep   = null
}
