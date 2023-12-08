include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/argocd/application_set.hcl"
}

inputs = {
  apps = [
    {
      helm_repo_url = "https://helm.releases.hashicorp.com"
      helm_chart_version = "0.27.0"
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
      helm_chart_version = "0.0.3" 
      values = <<EOT
      hosts:
      - "vault.{{domen}}"
      external: true
      virtualService:
        destination:
          host: vault
          port: 8200
      EOT
    }
  ]
}
