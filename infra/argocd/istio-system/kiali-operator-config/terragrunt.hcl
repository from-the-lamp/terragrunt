include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/argocd/application_set.hcl"
}

locals {
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env = local.environment_vars.locals.environment
}

dependency "infra_variables" {
  config_path = "${get_repo_root()}/${local.env}/gitlab/infra_variables"
  mock_outputs_allowed_terraform_commands = ["apply" ,"plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    variables = {
      openid_client_secret_kiali = "fake-secret"
    }
  }
}

inputs = {
  project = "infra"
  apps = [
    {
      helm_chart_name = "config"
      helm_chart_version = "0.0.5"
      values = <<EOT
      global:
        secret:
          oidc-secret: ${dependency.infra_variables.outputs.variables.openid_client_secret_kiali}
      EOT
    }
  ]
}
