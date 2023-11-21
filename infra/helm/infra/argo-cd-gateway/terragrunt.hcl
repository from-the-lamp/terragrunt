include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/k8s/helm.hcl"
}

locals {
  versions = read_terragrunt_config("${get_repo_root()}/_common/versions.hcl")
  gateway_version = local.versions.locals.gateway
  common_settings = read_terragrunt_config("${get_repo_root()}/terragrunt.hcl")
  helm_repo_url = local.common_settings.locals.infra_helm_repo_url
  helm_repo_user = local.common_settings.locals.helm_repo_user
  helm_repo_pass = local.common_settings.locals.helm_repo_pass
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env = local.environment_vars.locals.environment
  infra_zone = local.environment_vars.locals.infra_zone
}

dependency "cert-manager" {
  config_path = "../../istio-system/cert-manager"
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "output", "init", "destroy"]
  skip_outputs = true
}

dependency "argo-cd" {
  config_path = "../argo-cd"
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "output", "init", "destroy"]
  skip_outputs = true
}

inputs = {
  helm_repo_url = local.helm_repo_url
  helm_repo_user = local.helm_repo_user
  helm_repo_pass = local.helm_repo_pass
  helm_chart_name = "istio-gateway"
  helm_chart_version = local.gateway_version
  helm_values_file = <<-EOF
  hosts:
  - argocd.${local.infra_zone}
  external: true
  virtualService:
    destination:
      host: argo-cd-argocd-server
      port: 80
  EOF
}
