include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/argocd/application.hcl"
}

locals {
  common_settings = read_terragrunt_config("${get_repo_root()}/terragrunt.hcl")
  versions = read_terragrunt_config("${get_repo_root()}/_common/versions.hcl")
  config_version = local.versions.locals.config
  helm_repo_url = local.common_settings.locals.infra_helm_repo_url
  helm_repo_user = local.common_settings.locals.helm_repo_user
  helm_repo_pass = local.common_settings.locals.helm_repo_pass
}

inputs = {
  apps = [
    {
      helm_chart_name = "config"
      helm_chart_version = local.config_version
      values = <<EOT
      global:
        secret:
          iac: iac
        env:
          iac: |
            inrole: [postgres]
            user_flags:
            - superuser
            - createdb
            - createrole
      EOT
    }
  ]
}
