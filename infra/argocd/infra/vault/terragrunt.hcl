include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/argocd/application.hcl"
}

locals {
  versions = read_terragrunt_config("${get_repo_root()}/_common/versions.hcl")
  vault_version = local.versions.locals.vault
  istio_gateway_version = local.versions.locals.istio_gateway
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  infra_zone = local.environment_vars.locals.infra_zone
}

inputs = {
  ignore_difference = [
    {
      group = "cert-manager.io"
      kind = "Certificate"
      json_pointers = [
        "/spec/duration",
        "/spec/renewBefore"
      ]
      jq_path_expressions = []
    }
  ]
  apps = [
    {
      helm_repo_url = "https://helm.releases.hashicorp.com"
      helm_chart_version = local.vault_version
      wait = false
      values = <<EOT
      standalone:
        enabled: true
      injector:
        enabled: "false"
      EOT
    },
    {
      app_name = "vault-gateway"
      helm_chart_name = "istio-gateway"
      helm_chart_version = local.istio_gateway_version
      values = <<EOT
      hosts:
      - vault.from-the-lamp.com
      external: true
      virtualService:
        destination:
          host: vault
          port: 8200
      EOT
    }
  ]
}
