include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/k8s/helm.hcl"
}

locals {
  environment_vars     = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env                  = local.environment_vars.locals.environment
  common_settings      = read_terragrunt_config("${get_repo_root()}/terragrunt.hcl")
  versions             = read_terragrunt_config("${get_repo_root()}/_common/versions.hcl")
  cert_manager_version = local.versions.locals.cert_manager
}

dependency "istiod" {
  config_path = "../istiod"
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "output", "init", "destroy"]
  skip_outputs = true
}

inputs = {
  helm_repo_url      = "https://charts.jetstack.io"
  helm_chart_version = local.cert_manager_version
  helm_values_file = <<-EOF
  installCRDs: true
  EOF
}
