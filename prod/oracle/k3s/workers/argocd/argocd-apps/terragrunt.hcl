include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/k8s/helm.hcl"
}

locals {
  environment_vars                    = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env                                 = local.environment_vars.locals.environment
  common_settings                     = read_terragrunt_config("${get_repo_root()}/_common/settings.hcl")
  infra_helm_repo_url                 = local.common_settings.locals.infra_helm_repo_url
  versions                            = read_terragrunt_config("${get_repo_root()}/_common/versions.hcl")
  istio_system_version                = local.versions.locals.istio_system
  istio_gateway_version               = local.versions.locals.istio_gateway
  cert_manager_version                = local.versions.locals.cert_manager
  origin_ca_issuer_controller_version = local.versions.locals.origin_ca_issuer_controller
  origin_ca_issuer_version            = local.versions.locals.origin_ca_issuer
  role_with_rolebinding_version       = local.versions.locals.role_with_rolebinding
  argocd_apps_version                 = local.versions.locals.argocd_apps
}

dependency "masters" {
  config_path = "${get_repo_root()}/${local.env}/oracle/k3s/masters/instance_pool"
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "output", "init", "destroy"]
  skip_outputs = true
}

dependency "argocd" {
  config_path = "${get_repo_root()}/${local.env}/oracle/k3s/workers/argocd/argo-cd"
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "output", "init", "destroy"]
  skip_outputs = true
}

dependency "istiod" {
  config_path = "${get_repo_root()}/${local.env}/oracle/k3s/workers/istiod"
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "output", "init", "destroy"]
  skip_outputs = true
}

dependency "allow_https_from_all" {
  config_path = "${get_repo_root()}/${local.env}/oracle/nsg/allow_https_from_all"
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    id = "fake-id"
  }
}

dependency "get_infra_variables" {
  config_path = "${get_repo_root()}/${local.env}/gitlab/get_infra_variables"
  mock_outputs_allowed_terraform_commands = ["apply", "plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    map_variables = {
      cloudflare_originCAissuerKey = "fake-key"
    }
  }
}

inputs = {
  helm_external_repo = true
  helm_repo_url      = "https://argoproj.github.io/argo-helm"
  helm_chart_name    = "argocd-apps"
  helm_chart_version = local.argocd_apps_version
  helm_addition_setting = {
    # istio
    "applications[0].source.targetRevision" = local.istio_system_version
    # istio-ingressgateway
    "applications[1].source.targetRevision"           = local.istio_system_version
    "applications[1].source.helm.parameters[0].value" = dependency.allow_https_from_all.outputs.id
    # cert-manager
    "applications[2].source.targetRevision" = local.cert_manager_version
    # origin-ca-issuer-controller
    "applications[3].source.repoURL"        = local.infra_helm_repo_url
    "applications[3].source.targetRevision" = local.origin_ca_issuer_controller_version
    # origin-ca-issuer
    "applications[4].source.repoURL"                  = local.infra_helm_repo_url
    "applications[4].source.targetRevision"           = local.origin_ca_issuer_version
    "applications[4].source.helm.parameters[0].value" = dependency.get_infra_variables.outputs.map_variables.cloudflare_originCAissuerKey
    # role-with-rolebinding
    "applications[5].source.repoURL"        = local.infra_helm_repo_url
    "applications[5].source.targetRevision" = local.role_with_rolebinding_version
    # argocd-istio-gateway
    "applications[6].source.repoURL"        = local.infra_helm_repo_url
    "applications[6].source.targetRevision" = local.istio_gateway_version
  }
}
