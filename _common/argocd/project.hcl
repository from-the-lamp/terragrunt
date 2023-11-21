terraform {
  source = "${local.modules_url}/${local.module_name}//${local.module_dir}?ref=${local.module_version}"
}

locals {
  common_settings = read_terragrunt_config("${get_repo_root()}/terragrunt.hcl")
  modules_url = local.common_settings.locals.private_modules_base_url
  module_name = "argocd"
  module_dir = "project"
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
  name = basename(dirname(get_terragrunt_dir()))
  namespace = "infra"
  source_namespaces = ["infra"]
  source_repos = [
    "!https://gitlab.com/group/from-the-lamp/${basename(dirname(get_terragrunt_dir()))}/**",
     "https://gitlab.com/api/v4/projects/40582099/packages/helm/stable"
  ]
  cluster_resource_whitelist = [
    {
      group = ""
      kind = "Namespace"
    }
  ]
  namespace_resource_whitelist = [
    {
      group = "*"
      kind = "*"
    },
    {
      group = "cert-manager.io/v1"
      kind = "Certificate"
    },
  ]
}
