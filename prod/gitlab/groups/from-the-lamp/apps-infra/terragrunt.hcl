include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/k8s/helm.hcl"
}

locals {
  environment_vars          = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env                       = local.environment_vars.locals.environment
  versions                  = read_terragrunt_config("${get_repo_root()}/_common/versions.hcl")
  argocd_apps_version       = local.versions.locals.argocd_apps
  gitlab_runner_version     = local.versions.locals.gitlab_runner
  image_pull_secret_version = local.versions.locals.image_pull_secret
  common_settings           = read_terragrunt_config("${get_repo_root()}/_common/settings.hcl")
  infra_helm_repo_url       = local.common_settings.locals.infra_helm_repo_url
}

dependency "gitlab_runner_token" {
  config_path = "../gitlab_runner_token"
  mock_outputs_allowed_terraform_commands = ["apply" ,"plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    "runners_token" = "fake-token"
  }
}

dependency "gitlab_vars" {
  config_path = "${get_repo_root()}/${local.env}/gitlab/get_infra_variables"
  mock_outputs_allowed_terraform_commands = ["apply" ,"plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    map_variables = {
      gitlab_docker_registry_token = "fake-token"
    }
  }
}

inputs = {
  helm_external_repo = true
  helm_repo_url      = "https://argoproj.github.io/argo-helm"
  helm_chart_name    = "argocd-apps"
  helm_chart_version = local.argocd_apps_version
  helm_addition_setting = {
    # project
    "projects[0].name"                      = basename(dirname(get_terragrunt_dir()))
    "projects[0].sourceNamespaces[0]"       = basename(dirname(get_terragrunt_dir()))
    "projects[0].destinations[0].namespace" = basename(dirname(get_terragrunt_dir()))
    "projects[0].sourceNamespaces[0]"       = basename(dirname(get_terragrunt_dir()))
    # image-pull-secret
    "applications[0].source.repoURL"                  = local.infra_helm_repo_url
    "applications[0].source.targetRevision"           = local.image_pull_secret_version
    "applications[0].destination.namespace"           = basename(dirname(get_terragrunt_dir()))
    "applications[0].source.helm.parameters[0].value" = dependency.gitlab_vars.outputs.map_variables.gitlab_docker_registry_token
    "applications[0].namespace"                 = basename(dirname(get_terragrunt_dir()))
    "applications[0].project"                   = basename(dirname(get_terragrunt_dir()))
    # gitlab-runner
    "applications[1].source.targetRevision"           = local.gitlab_runner_version
    "applications[1].destination.namespace"           = basename(dirname(get_terragrunt_dir()))
    "applications[1].source.helm.parameters[0].value" = dependency.gitlab_runner_token.outputs.runners_token
    "applications[1].namespace"                 = basename(dirname(get_terragrunt_dir()))
    "applications[1].project"                   = basename(dirname(get_terragrunt_dir()))
  }
}
