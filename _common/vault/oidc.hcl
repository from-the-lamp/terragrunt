terraform {
  source = "${local.modules_url}/${local.module_name}//${local.module_dir}?ref=${local.module_version}"
}

locals {
  common_settings = read_terragrunt_config("${get_repo_root()}/terragrunt.hcl")
  modules_url = local.common_settings.locals.private_modules_base_url
  module_name = "vault"
  module_dir = "oidc"
  module_version = "main"
  vault_base_url = local.common_settings.locals.vault_base_url
  vault_openid_client_id = local.common_settings.locals.vault_openid_client_id
  gitlab_base_url = local.common_settings.locals.gitlab_base_url
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env = local.environment_vars.locals.environment
}

dependency "get_infra_variables" {
  config_path = "${get_repo_root()}/${local.env}/gitlab/get_infra_variables"
  mock_outputs_allowed_terraform_commands = ["apply" ,"plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    variables = {
      vault_openid_client_secret = "fake-secret"
      vault_token = "fake-token"
    }
  }
}

inputs = {
  host = "https://${local.vault_base_url}"
  token = dependency.get_infra_variables.outputs.variables.vault_token
  path = "gitlab"
  bound_issuer = "https://${local.gitlab_base_url}"
  oidc_client_id = local.vault_openid_client_id
  oidc_client_secret = dependency.get_infra_variables.outputs.variables.vault_openid_client_secret
  oidc_discovery_url = "https://${local.gitlab_base_url}"
  bound_claims = { "groups" = "from-the-lamp" }
  allowed_redirect_uris = ["https://${local.vault_base_url}/ui/vault/auth/gitlab/oidc/callback"]
  token_policies = ["admin"]
}
