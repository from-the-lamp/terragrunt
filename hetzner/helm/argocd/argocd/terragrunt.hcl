include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "common" {
  path = "${get_repo_root()}/_common/hetzner/helm.hcl"
}

# ArgoCD's manifests reference ExternalSecret CRDs; applying it in parallel
# with external-secrets (the default under `run --all`) races the CRD
# registration and intermittently fails. Force external-secrets first.
dependency "external_secrets" {
  config_path                             = "${get_repo_root()}/hetzner/helm/external-secrets/external-secrets"
  mock_outputs_allowed_terraform_commands = ["plan", "apply", "validate", "output", "init", "destroy"]
  skip_outputs                            = true
}

inputs = {
  helm_chart_name    = "lamp-argocd"
  helm_chart_version = "0.4.0"
  # Chart default leaves this empty, which registers the in-cluster Secret
  # with no name at all — Applications in any project other than "default"
  # then fail to resolve destination.name: in-cluster (project destination
  # matching needs an actual registered cluster name, not just the
  # ArgoCD-wide magic string), erroring "destination server '' ... do not
  # match any of the allowed destinations".
  helm_values = [
    yamlencode({
      defaultClusterName = "in-cluster"
      # Top-level (not under argo-cd:) — this chart's own "global" key,
      # propagated by Helm into every subchart including the nested argo-cd
      # dependency. Chart default is the internal-only domain — dex derives
      # its issuer/redirect URIs from this, so it has to match wherever the
      # login flow is actually reachable from (the public route).
      global = {
        domain = "argocd.from-the-lamp.work"
      }
      # Chart default is "oracle" (infra/prod-0's ClusterSecretStore) — not
      # applicable here. Backs argocd-sso-secrets (GitLab OIDC client
      # id/secret) from the "argocd" entry in our own Vault (platform
      # mount) — needs oauthClientID/SecretProperty support added to
      # sso.yaml first (not yet published as of this pin).
      externalSecrets = {
        name = "vault"
      }
      remoteSecretKeys = {
        oauthClientID             = "argocd"
        oauthClientIDProperty     = "oauth_client_id"
        oauthClientSecret         = "argocd"
        oauthClientSecretProperty = "oauth_client_secret"
      }
      # Reuses the org's existing GitLab OAuth Application (client id/secret
      # already in Vault) — its redirect URI list needs
      # https://argocd.from-the-lamp.work/api/dex/callback added on the
      # GitLab side. "from-the-lamp" GitLab group maps to ArgoCD's built-in
      # admin role (see configs.rbac below), same group oauth2-proxy uses.
      argo-cd = {
        configs = {
          cm = {
            "dex.config" = <<-EOT
              connectors:
                - type: gitlab
                  id: gitlab
                  name: GitLab
                  config:
                    baseURL: https://gitlab.com
                    clientID: $argocd-sso-secrets:clientId
                    clientSecret: $argocd-sso-secrets:clientSecret
                    redirectURI: https://argocd.from-the-lamp.work/api/dex/callback
                    groups:
                      - from-the-lamp
            EOT
          }
          # configs.rbac is a sibling of configs.cm — maps to the separate
          # argocd-rbac-cm ConfigMap. (The chart's own default values wedge
          # an "rbac" key under configs.cm too, but argocd-cm has no such
          # field; that data is inert.)
          rbac = {
            "policy.csv" = "g, from-the-lamp, role:admin\n"
          }
        }
      }
    })
  ]
}
