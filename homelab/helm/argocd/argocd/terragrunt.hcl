include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "common" {
  path = "${get_repo_root()}/_common/homelab/helm.hcl"
}

# Same CRD-registration race as Hetzner - force external-secrets first.
dependency "external_secrets" {
  config_path                             = "${get_repo_root()}/homelab/helm/external-secrets/external-secrets"
  mock_outputs_allowed_terraform_commands = ["plan", "apply", "validate", "output", "init", "destroy"]
  skip_outputs                            = true
}

inputs = {
  helm_chart_name    = "lamp-argocd"
  helm_chart_version = "0.0.5"
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
      # dependency. Dex derives its issuer/redirect URIs from this.
      # argocd.from-the-lamp.work, not .internal.from-the-lamp.work: homelab
      # has no public gateway at all, istio-gateway-internal serves the
      # bare apex domain here (see apps/homelab/platform/istio-system) -
      # matches the .work=private-Tailscale/.com=public convention.
      global = {
        domain = "argocd.from-the-lamp.work"
      }
      # Backs argocd-sso-secrets (GitLab OIDC client id/secret) from the
      # "argocd" entry in our own Vault (platform mount) - same ClusterSecretStore
      # every other homelab app uses.
      externalSecrets = {
        name = "vault"
      }
      sso = {
        enabled    = true
        secretName = "argocd-sso-secrets"
        oauthClientID = {
          key      = "argocd"
          property = "oauth_client_id"
        }
        oauthClientSecret = {
          key      = "argocd"
          property = "oauth_client_secret"
        }
      }
      # prod-0/prod-1 move here from Hetzner's ArgoCD as part of the same
      # relocation - this is now the one ArgoCD managing them, via their
      # own Tailscale API server proxy (credential-less). Requires
      # tag:argocd-egress extended to a new tag:k3s-operator-homelab
      # identity (infra/tailscale/acl) so this cluster's egress is allowed
      # to reach them - see homelab/platform/tailscale's apiServerProxyConfig
      # equivalent on the Hetzner side for the egress Service pattern.
      externalClusters = [
        {
          name           = "prod-0-tailscale"
          tailscaleProxy = true
          server         = "https://prod-0-k8s-operator.tailscale.svc.cluster.local"
          # The proxy's TLS listener validates SNI against its real tailnet
          # hostname and 500s ("invalid domain") against anything else.
          tailnetFqdn = "prod-0-k8s-operator.coin-cichlid.ts.net"
        },
        {
          name           = "prod-1-tailscale"
          tailscaleProxy = true
          server         = "https://prod-1-k8s-operator.tailscale.svc.cluster.local"
          tailnetFqdn    = "prod-1-k8s-operator.coin-cichlid.ts.net"
        },
      ]
      # Reuses the org's existing GitLab OAuth Application (same Vault
      # secret as Hetzner's) - its redirect URI list needs
      # https://argocd.from-the-lamp.work/api/dex/callback added on the
      # GitLab side (manual step, not Terraform-managed - same as Hetzner's
      # own redirect URI was). "from-the-lamp" GitLab group maps to
      # ArgoCD's built-in admin role (see configs.rbac below).
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

        # Mirrors Hetzner's sizing (same workload, single node here has
        # more headroom overall - revisit only if actually constrained).
        controller = {
          resources = {
            requests = { cpu = "150m", memory = "1536Mi" }
            limits   = { memory = "3072Mi" }
          }
        }
        server = {
          resources = {
            requests = { cpu = "10m", memory = "96Mi" }
            limits   = { memory = "256Mi" }
          }
        }
        repoServer = {
          resources = {
            requests = { cpu = "75m", memory = "128Mi" }
            # 256Mi was OOMKilling repeatedly (confirmed live: 8 restarts in
            # under 4h) - bumped with headroom instead of a second nudge.
            limits = { memory = "512Mi" }
          }
        }
        dex = {
          resources = {
            requests = { cpu = "5m", memory = "48Mi" }
            limits   = { memory = "512Mi" }
          }
        }
        applicationSet = {
          resources = {
            requests = { cpu = "15m", memory = "64Mi" }
            limits   = { memory = "128Mi" }
          }
        }
        notifications = {
          resources = {
            requests = { cpu = "5m", memory = "48Mi" }
            limits   = { memory = "96Mi" }
          }
        }
      }
    })
  ]
}
