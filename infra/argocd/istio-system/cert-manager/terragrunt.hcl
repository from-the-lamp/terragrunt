include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/argocd/application.hcl"
}

locals {
  versions = read_terragrunt_config("${get_repo_root()}/_common/versions.hcl")
  cert_manager_version = local.versions.locals.cert_manager
}

dependency "istiod" {
  config_path = "../istiod"
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "output", "init", "destroy"]
  skip_outputs = true
}

inputs = {
  project = "infra"
  apps = [
    {
      helm_repo_url = "https://charts.jetstack.io"
      helm_chart_version = local.cert_manager_version
      values = <<EOT
      installCRDs: true
      EOT
    }
  ]
}
