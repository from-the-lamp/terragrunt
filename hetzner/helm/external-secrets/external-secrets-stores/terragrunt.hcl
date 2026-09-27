include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "common" {
  path = "${get_repo_root()}/_common/hetzner/helm.hcl"
}

dependency "external-secrets" {
  config_path                             = "../external-secrets"
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "output", "init", "destroy"]
  skip_outputs                            = true
}

inputs = {
  helm_chart_name = "lamp-external-secrets-stores"
  # Bump once the "vault" provider template is added and published (see
  # infra/helm-charts lamp-external-secrets/lamp-external-secrets-stores).
  helm_chart_version = "0.0.3"
  helm_values = [yamlencode({
    clusterStores = [
      {
        name = "vault"
        type = "vault"
        # In-cluster Service DNS name — argo-apps' apps/platform/vault
        # deploys the actual Vault StatefulSet (bank-vaults), not Terraform.
        server = "http://vault.vault:8200"
        # KV v2 mount created by lamp-vault-server's kvMounts (see
        # argo-apps apps/platform/vault/values.yaml).
        path = "platform"
        role = "external-secrets"
        serviceAccount = {
          name      = "external-secrets"
          namespace = "external-secrets"
        }
      }
    ]
  })]
}
