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
      helm_chart_version = "0.4.0"
      values = <<EOT
      defaultVaultConnection:
        enabled: true
        address: "http://vault.infra.svc.cluster.local:8200"
        skipTLSVerify: false
      EOT
    }
  ]
}
