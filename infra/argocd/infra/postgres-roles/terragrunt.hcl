include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/argocd/application_set.hcl"
}

locals {
  versions = read_terragrunt_config("${get_repo_root()}/_common/versions.hcl")
  config_version = local.versions.locals.config
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
