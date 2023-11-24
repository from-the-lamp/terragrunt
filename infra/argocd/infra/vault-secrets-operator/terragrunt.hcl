include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/argocd/application_set.hcl"
}

locals {
  versions = read_terragrunt_config("${get_repo_root()}/_common/versions.hcl")
  vault_secrets_operator_version = local.versions.locals.vault_secrets_operator
}

inputs = {
  apps = [
    {
      helm_repo_url = "https://helm.releases.hashicorp.com"
      helm_chart_version = local.vault_secrets_operator_version
      values = <<EOT
      defaultVaultConnection:
        enabled: true
        address: "http://vault.infra.svc.cluster.local:8200"
        skipTLSVerify: false
      EOT
    }
  ]
}
