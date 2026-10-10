include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "common" {
  path = "${get_repo_root()}/_common/homelab/helm.hcl"
}

dependency "external-secrets" {
  config_path                             = "../external-secrets"
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "output", "init", "destroy"]
  skip_outputs                            = true
}

inputs = {
  helm_chart_name    = "lamp-external-secrets-stores"
  helm_chart_version = "0.0.3"
  helm_values = [yamlencode({
    clusterStores = [
      {
        name = "vault"
        type = "vault"
        # In-cluster Service DNS name - argo-apps' apps/homelab/platform/vault
        # deploys the actual Vault StatefulSet (bank-vaults), not Terraform.
        # This is a SEPARATE Vault instance from Hetzner's own - same chart,
        # same in-cluster address convention, independent data.
        server = "http://vault.vault:8200"
        path   = "platform"
        role   = "external-secrets"
        serviceAccount = {
          name      = "external-secrets"
          namespace = "external-secrets"
        }
      }
    ]
  })]
}
