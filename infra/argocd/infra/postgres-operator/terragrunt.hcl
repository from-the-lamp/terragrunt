include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/argocd/application.hcl"
}

locals {
  versions = read_terragrunt_config("${get_repo_root()}/_common/versions.hcl")
  gateway = local.versions.locals.gateway
  postgres_operator_version = local.versions.locals.postgres_operator
}

dependency "postgres-roles" {
  config_path = "../postgres-roles"
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "output", "init", "destroy"]
  skip_outputs = true
}

inputs = {
  apps = [
    {
      helm_repo_url = "https://opensource.zalando.com/postgres-operator/charts/postgres-operator"
      helm_chart_version = local.postgres_operator_version
      values = <<EOT
      image:
        registry: registry.gitlab.com
        repository: from-the-lamp/infra/docker-images/zalando-postgres-operator
        tag: 119ad024
      configKubernetes:
        infrastructure_roles_secrets:
        - secretname: "postgres-roles-env"
          userkey: "user1"
          passwordkey: "password1"
          rolekey: "inrole1"
      EOT
    }
  ]
}
