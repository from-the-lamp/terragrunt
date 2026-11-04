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
  # Reuses root.hcl's own gitlab_token (TF_HTTP_PASSWORD) - already an
  # Owner-scoped PAT (it has to be, for the state backend's own API access),
  # so a second, separately-named token here would be the same credential
  # under a different name, not an actual privilege reduction.
  contents = <<EOF
provider "gitlab" {
  token = "${local.common_settings.locals.gitlab_token}"
}
EOF
}
