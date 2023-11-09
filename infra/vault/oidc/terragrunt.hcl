include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/vault/oidc.hcl"
}

locals {
  common_settings = read_terragrunt_config("${get_repo_root()}/terragrunt.hcl")
  gitlab_base_url = local.common_settings.locals.gitlab_base_url
  oidc_client_id = local.common_settings.locals.oidc_client_id
  vault_base_url = local.common_settings.locals.vault_base_url
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env = local.environment_vars.locals.environment
}

dependency "get_infra_variables" {
  config_path = "${get_repo_root()}/${local.env}/gitlab/get_infra_variables"
  mock_outputs_allowed_terraform_commands = ["apply" ,"plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    variables = {
      oidc_client_secret = "fake-secret"
    }
  }
}

inputs = {
  bound_issuer = local.gitlab_base_url
  oidc_discovery_url = "https://${local.gitlab_base_url}"
  oidc_client_id = local.oidc_client_id
  oidc_client_secret = dependency.get_infra_variables.outputs.variables.oidc_client_secret
  path = "gitlab"
  role_name = "admin"
  token_policies = ["admin"]
  bound_claims = {
    "groups" = "from-the-lamp"
  }
  allowed_redirect_uris = [
    "https://${local.vault_base_url}/ui/vault/auth/gitlab/oidc/callback"
  ]
}
