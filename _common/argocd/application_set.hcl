terraform {
  source = "${local.modules_url}/${local.module_name}//${local.module_dir}?ref=${local.module_version}"
}

locals {
  common_settings = read_terragrunt_config("${get_repo_root()}/terragrunt.hcl")
  modules_url = local.common_settings.locals.private_modules_base_url
  module_name = "argocd"
  module_dir = "application_set"
  module_version = "main"
  infra_helm_repo_url = local.common_settings.locals.infra_helm_repo_url
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env = local.environment_vars.locals.environment
  infra_zone = local.environment_vars.locals.infra_zone
  versions = read_terragrunt_config("${get_repo_root()}/_common/versions.hcl")
  base_helm_chart_version = local.versions.locals.base_helm_chart
}

inputs = {
  server_addr = "argocd.from-the-lamp.work:443"
  auth_token = get_env("argo_auth_token")
  app_name = "${basename(dirname(get_terragrunt_dir()))}-${basename(get_terragrunt_dir())}"
  release_name = basename(get_terragrunt_dir())
  app_namespace = "infra"
  dest_cluster_name = "prod"
  dest_namespace = basename(dirname(get_terragrunt_dir()))
  helm_repo_url = local.infra_helm_repo_url
  helm_chart_name = basename(get_terragrunt_dir())
  helm_chart_version = local.base_helm_chart_version
  project = basename(dirname(get_terragrunt_dir()))
  sync_options = ["CreateNamespace=true"]
  namespace_labels = {
    "istio-injection" = "enabled"
  }
  dest_cluster_list = [
    {
      cluster = "prod"
    }
  ]
}
