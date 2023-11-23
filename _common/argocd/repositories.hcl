terraform {
  source = "${local.modules_url}/${local.module_name}//${local.module_dir}?ref=${local.module_version}"
}

locals {
  common_settings = read_terragrunt_config("${get_repo_root()}/terragrunt.hcl")
  modules_url = local.common_settings.locals.private_modules_base_url
  module_name = "argocd"
  module_dir = "repositories"
  module_version = "main"
  infra_helm_repo_url = local.common_settings.locals.infra_helm_repo_url
}

inputs = {
  server_addr = "argocd.from-the-lamp.work:443"
  auth_token = get_env("argo_auth_token")
  repositories = [
    {
      name = "infra"
      repo = local.infra_helm_repo_url
    }
  ]
}
