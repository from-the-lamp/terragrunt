include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/argocd/application_set.hcl"
}

locals {
  common_settings = read_terragrunt_config("${get_repo_root()}/terragrunt.hcl")
  vault_base_url = local.common_settings.locals.vault_base_url
  openid_client_id_vault = local.common_settings.locals.openid_client_id_vault
  gitlab_base_url = local.common_settings.locals.gitlab_base_url
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env = local.environment_vars.locals.environment
}

dependency "get_infra_variables" {
  config_path = "${get_repo_root()}/${local.env}/gitlab/get_infra_variables"
  mock_outputs_allowed_terraform_commands = ["apply" ,"plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    variables = {
      openid_client_secret_vault = "fake-secret"
    }
  }
}

inputs = {
  apps = [
    {
      helm_chart_name = "crossplane-workspaces"
      helm_chart_version = "0.0.18"
      values = <<EOT
      workspaces:
        vault:
          enabled: true
          dir: oidc
          varmap:
            bound_claims:
              groups: "from-the-lamp"
            allowed_redirect_uris:
            - "https://${local.vault_base_url}/ui/vault/auth/gitlab/oidc/callback"
            token_policies:
            - "admin"
          vars:
          - key: path
            value: "gitlab"
          - key: bound_issuer
            value: "https://${local.gitlab_base_url}"
          - key: oidc_client_id
            value: "${local.openid_client_id_vault}"
          - key: oidc_client_secret
            value: "${dependency.get_infra_variables.outputs.variables.openid_client_secret_vault}"
          - key: oidc_discovery_url
            value: "https://${local.gitlab_base_url}"
          - key: role_name
            value: "admin"
      providers:
        vault:
          enabled: true
      EOT
    }
  ]
}
