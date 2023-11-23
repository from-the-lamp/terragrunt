include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/argocd/application_set.hcl"
}

locals {
  common_settings = read_terragrunt_config("${get_repo_root()}/terragrunt.hcl")
  vault_base_url = local.common_settings.locals.vault_base_url
  versions = read_terragrunt_config("${get_repo_root()}/_common/versions.hcl")
  crossplane_workspaces_version = local.versions.locals.crossplane_workspaces
  helm_repo_url = local.common_settings.locals.infra_helm_repo_url
  helm_repo_user = local.common_settings.locals.helm_repo_user
  helm_repo_pass = local.common_settings.locals.helm_repo_pass
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
  apps = [
    {
      helm_chart_name = "crossplane-workspaces"
      helm_chart_version = local.crossplane_workspaces_version
      values = <<EOT
      workspaces:
        vault:
          enabled: true
          dir: mount_kvv2
          vars:
          - key: path
            value: "secrets"
      providers:
        vault:
          enabled: true
      EOT
    }
  ]
}
