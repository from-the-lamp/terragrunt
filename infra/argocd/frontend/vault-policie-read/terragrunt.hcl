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

dependency "get_infra_variables" {
  config_path = "${get_repo_root()}/${local.env}/gitlab/get_infra_variables"
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
      helm_chart_version = "0.0.18"
      values = <<EOT
      workspaces:
        vault:
          enabled: true
          dir: policy
          varmap:
            policy_value:
            - path: "secrets/*"
              capabilities: ["read"]
          vars:
          - key: policy_name
            value: "read"
      providers:
        vault:
          enabled: true
      EOT
    }
  ]
}
