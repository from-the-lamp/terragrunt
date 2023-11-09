include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/k8s/helm.hcl"
}

locals {
  versions = read_terragrunt_config("${get_repo_root()}/_common/versions.hcl")
  origin_ca_issuer_controller_version = local.versions.locals.origin_ca_issuer_controller
  common_settings = read_terragrunt_config("${get_repo_root()}/terragrunt.hcl")
  helm_repo_url   = local.common_settings.locals.infra_helm_repo_url
  helm_repo_user  = local.common_settings.locals.helm_repo_user
  helm_repo_pass  = local.common_settings.locals.helm_repo_pass
}

dependency "istiod" {
  config_path = "../istiod"
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "output", "init", "destroy"]
  skip_outputs = true
}

inputs = {
  helm_repo_url      = local.helm_repo_url
  helm_repo_user     = local.helm_repo_user
  helm_repo_pass     = local.helm_repo_pass
  helm_chart_version = local.origin_ca_issuer_controller_version
  helm_values_file = <<-EOF
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
  EOF
}
