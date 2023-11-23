include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/argocd/application_set.hcl"
}

locals {
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env = local.environment_vars.locals.environment
  versions = read_terragrunt_config("${get_repo_root()}/_common/versions.hcl")
  origin_ca_issuer_version = local.versions.locals.origin_ca_issuer
}

dependency "origin-ca-issuer-controller" {
  config_path = "../origin-ca-issuer-controller"
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "output", "init", "destroy"]
  skip_outputs = true
}

dependency "get_infra_variables" {
  config_path = "${get_repo_root()}/${local.env}/gitlab/get_infra_variables"
  mock_outputs_allowed_terraform_commands = ["apply", "plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    variables = {
      cloudflare_originCAissuerKey = "fake-key"
    }
  }
}

inputs = {
  project = "infra"
  apps = [
    {
      helm_chart_version = local.origin_ca_issuer_version
      values = <<EOT
      originCAissuerKey: ${dependency.get_infra_variables.outputs.variables.cloudflare_originCAissuerKey}
      EOT
    }
  ]
}
