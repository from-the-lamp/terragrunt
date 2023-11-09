include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/k8s/helm.hcl"
}

locals {
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env              = local.environment_vars.locals.environment
  versions                 = read_terragrunt_config("${get_repo_root()}/_common/versions.hcl")
  origin_ca_issuer_version = local.versions.locals.origin_ca_issuer
  common_settings = read_terragrunt_config("${get_repo_root()}/terragrunt.hcl")
  helm_repo_url   = local.common_settings.locals.infra_helm_repo_url
  helm_repo_user  = local.common_settings.locals.helm_repo_user
  helm_repo_pass  = local.common_settings.locals.helm_repo_pass
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
  helm_repo_url      = local.helm_repo_url
  helm_repo_user     = local.helm_repo_user
  helm_repo_pass     = local.helm_repo_pass
  helm_chart_version = local.origin_ca_issuer_version
  helm_values_file = <<-EOF
  originCAissuerKey: ${dependency.get_infra_variables.outputs.variables.cloudflare_originCAissuerKey}
  EOF
}
