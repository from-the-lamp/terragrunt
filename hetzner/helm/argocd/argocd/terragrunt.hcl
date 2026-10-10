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
  helm_chart_version = "0.0.2"
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
      # dependency. Dex derives its issuer/redirect URIs from this, so it has
      # to match wherever the login flow is actually reachable from — the
      # public route was removed, ArgoCD is internal-only now.
      global = {
        domain = "argocd.internal.from-the-lamp.work"
      }
      # Chart default is "oracle" (infra/prod-0's ClusterSecretStore) — not
      # applicable here. Backs argocd-sso-secrets (GitLab OIDC client
      # id/secret) from the "argocd" entry in our own Vault (platform
      # mount).
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
      # prod-1 and prod-0 are separate physical clusters this same ArgoCD
      # also manages. Their kubeconfigs already live in Vault (seeded for
      # the toolhive kubernetes-mcp servers) - reused as-is rather than
      # duplicated under new fields. prod-1's kubeconfig carries a long-lived
      # ServiceAccount bearer token; prod-0's carries a client cert/key pair
      # instead - the chart's external-clusters.yaml template parses
      # whichever is present.
      externalClusters = [
        {
          name           = "prod-1"
          remoteKey      = "toolhive"
          remoteProperty = "kubeconfig-prod-1"
        },
        {
          name           = "prod-0"
          remoteKey      = "toolhive"
          remoteProperty = "kubeconfig-prod-0"
        },
        # Homelab's single-node bare-metal Talos cluster - this ArgoCD
        # manages it the same way as prod-0/prod-1 (remote kubeconfig, not
        # its own ArgoCD instance - see infra/terraform/terragrunt's
        # homelab/README.md for why). NOT YET SEEDED: `kubeconfig-homelab`
        # doesn't exist in Vault's "toolhive" entry until the node is
        # actually bootstrapped and its kubeconfig (homelab/talos/access's
        # kubeconfig_raw output) is pushed there by hand. Until it is, this
        # entry just fails to resolve - harmless, same as any other
        # not-yet-seeded ExternalSecret property.
        {
          name           = "homelab"
          remoteKey      = "toolhive"
          remoteProperty = "kubeconfig-homelab"
        },
        # Parallel, credential-less registration of prod-0/prod-1 via their
        # Tailscale API server proxy (apiServerProxyConfig, allowImpersonation)
        # instead of the static kubeconfig above - see
        # infra/tailscale/acl's tag:argocd-egress grant and
        # apps/hetzner-infra/platform/tailscale's egress Services (the
        # tailscale.svc.cluster.local hostnames below). Deliberately a
        # DIFFERENT cluster "name" than the existing prod-0/prod-1 entries
        # (not yet replacing them) - lets this path be verified end-to-end
        # before any Application's destination.name is switched over.
        {
          name           = "prod-0-tailscale"
          tailscaleProxy = true
          server         = "https://prod-0-k8s-operator.tailscale.svc.cluster.local"
        },
        {
          name           = "prod-1-tailscale"
          tailscaleProxy = true
          server         = "https://prod-1-k8s-operator.tailscale.svc.cluster.local"
        },
      ]
      # Reuses the org's existing GitLab OAuth Application (client id/secret
      # already in Vault) — its redirect URI list needs
      # https://argocd.internal.from-the-lamp.work/api/dex/callback added on
      # the GitLab side (and the old public one removed). "from-the-lamp"
      # GitLab group maps to ArgoCD's built-in admin role (see configs.rbac
      # below), same group oauth2-proxy uses.
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
                    redirectURI: https://argocd.internal.from-the-lamp.work/api/dex/callback
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

        # Chart default leaves every component with no resources at all.
        # application-controller had grown to ~1.4-2GB with nothing declared
        # (invisible to the scheduler) and was one of the two biggest
        # contributors to the node-wide memory exhaustion behind the
        # recurring hetzner-cp-2 NotReady flaps (the other being
        # kube-apiserver itself, which isn't ours to size). Sized from
        # ~6h of real victoria-metrics usage (avg for requests, max*1.5 for
        # memory limits); no cpu limits per policy - only requests.
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
            limits   = { memory = "256Mi" }
          }
        }
        dex = {
          # 128Mi was fine with no connectors configured, but OOM-kills
          # (observed as SIGSEGV/exit 139, no log output - this kernel/
          # cgroup setup doesn't report it as a normal OOMKilled) once a
          # real GitLab connector actually loads (OIDC discovery, group
          # claims, etc. push it over). Confirmed by bumping live to 512Mi
          # and watching the pod go Running immediately.
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
