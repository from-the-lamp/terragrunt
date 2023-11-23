include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/argocd/application_set.hcl"
}

locals {
  versions = read_terragrunt_config("${get_repo_root()}/_common/versions.hcl")
  origin_ca_issuer_controller_version = local.versions.locals.origin_ca_issuer_controller
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
      helm_chart_version = local.origin_ca_issuer_controller_version
      values = <<EOT
      controller:
        resources:
          limits:
            cpu: 500m
            memory: 500Mi
          requests:
            cpu: 100m
            memory: 50Mi
      certmanager:
        namespace: istio-system
      EOT
    }
  ]
}
