include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/argocd/application_set.hcl"
}

locals {
  common_settings = read_terragrunt_config("${get_repo_root()}/terragrunt.hcl")
  vault_base_url = local.common_settings.locals.vault_base_url
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env = local.environment_vars.locals.environment
}

dependency "infra_variables" {
  config_path = "${get_repo_root()}/${local.env}/gitlab/infra_variables"
  mock_outputs_allowed_terraform_commands = ["apply" ,"plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    variables = {
      vault_token = "fake-token"
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
      helm_chart_name = "crossplane-workspaces"
      helm_chart_version = "0.1.0"
      values = <<EOT
      workspaces:
        vault:
          enabled: true
          dir: kubernetes_auth_role
          varmap:
            service_account_names:
            - default
            service_account_namespaces:
            - backend
            token_policies:
            - read
          vars:
          - key: role_name
            value: "backend-app"
      EOT
    }
  ]
}
