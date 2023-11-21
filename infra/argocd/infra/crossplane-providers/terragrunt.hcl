include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/argocd/application.hcl"
}

locals {
  versions = read_terragrunt_config("${get_repo_root()}/_common/versions.hcl")
  crossplane_providers_version = local.versions.locals.crossplane_providers
}

dependency "crossplane" {
  config_path = "../crossplane"
  mock_outputs_allowed_terraform_commands = ["apply", "plan", "validate", "output", "init", "destroy"]
  skip_outputs = true
}

inputs = {
  apps = [
    {
      helm_chart_name = "crossplane-providers"
      helm_chart_version = local.crossplane_providers_version
    }
  ]
}
