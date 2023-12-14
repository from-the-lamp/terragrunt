include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/argocd/application_set.hcl"
}

locals {
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env = local.environment_vars.locals.environment
  common_settings = read_terragrunt_config("${get_repo_root()}/terragrunt.hcl")
  openid_client_id_pgadmin4 = local.common_settings.locals.openid_client_id_pgadmin4
}

dependency "infra_variables" {
  config_path = "${get_repo_root()}/${local.env}/gitlab/infra_variables"
  mock_outputs_allowed_terraform_commands = ["apply" ,"plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    variables = {
      openid_client_secret_pgadmin4 = "fake-secret"
    }
  }
}

inputs = {
  dest_cluster_list = [
    {
      cluster = "prod-0"
      domen = "from-the-lamp.com"
    }
  ]
  apps = [
    {
      release_name = "pgadmin4-config"
      helm_chart_name = "config"
      helm_chart_version = "0.0.5"
      values = <<EOT
      global:
        secret:
          OAUTH2_CLIENT_ID: ${local.openid_client_id_pgadmin4}
          OAUTH2_CLIENT_SECRET: "${dependency.infra_variables.outputs.variables.openid_client_secret_pgadmin4}"
          pgpassfile: |
            postgresql-hl:5432:*:postgres:postgres
        env: 
          config_local.py: |-
            import os
            AUTHENTICATION_SOURCES = ['oauth2', 'internal']
            OAUTH2_AUTO_CREATE_USER = True
            MASTER_PASSWORD_REQUIRED = False
            OAUTH2_CONFIG = [
              {
                'OAUTH2_NAME': 'gitlab',
                'OAUTH2_DISPLAY_NAME': 'Gitlab',
                'OAUTH2_CLIENT_ID': os.environ['OAUTH2_CLIENT_ID'],
                'OAUTH2_CLIENT_SECRET': os.environ['OAUTH2_CLIENT_SECRET'],
                'OAUTH2_TOKEN_URL': 'https://gitlab.com/oauth/token',
                'OAUTH2_AUTHORIZATION_URL': 'https://gitlab.com/oauth/authorize',
                'OAUTH2_API_BASE_URL': 'https://gitlab.com/oauth/',
                'OAUTH2_SERVER_METADATA_URL': 'https://gitlab.com/.well-known/openid-configuration',
                'OAUTH2_USERINFO_ENDPOINT': 'userinfo',
                'OAUTH2_SCOPE': 'openid email profile',
                'OAUTH2_ICON': 'fa-gitlab',
                'OAUTH2_BUTTON_COLOR': '#E24329',
              }
            ]
      EOT
    }
  ]
}