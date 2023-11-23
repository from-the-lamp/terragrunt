include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/argocd/application_set.hcl"
}

locals {
  versions = read_terragrunt_config("${get_repo_root()}/_common/versions.hcl")
  postgres_version = local.versions.locals.postgres
}

inputs = {
  apps = [
    {
      helm_chart_name = "postgres"
      helm_chart_version = local.postgres_version
      values = <<EOT
      enabled: "true"
      teamId: backend
      volume:
        size: 5Gi
      numberOfInstances: "1"
      EOT
    }
  ]
}
