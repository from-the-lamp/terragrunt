include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "common" {
  path = "${get_repo_root()}/_common/tailscale/acl.hcl"
}

inputs = {
  overwrite_existing_content = true

  tag_owners = {
    "tag:exit"                 = ["autogroup:admin"]
    "tag:k3s-operator-infra"   = ["autogroup:admin"]
    "tag:k3s-proxy-infra"      = ["autogroup:admin"]
    "tag:k3s-operator-prod-0"  = ["autogroup:admin"]
    "tag:k3s-proxy-prod-0"     = ["autogroup:admin"]
    "tag:k3s-operator-hetzner" = ["autogroup:admin"]
    "tag:k3s-proxy-hetzner"    = ["autogroup:admin"]
    # Dedicated identity for ArgoCD's own connection to prod-0/prod-1's
    # Tailscale API server proxy - deliberately NOT tag:k3s-proxy-hetzner
    # (the subnet-router every pod on hetzner-cp-1 already routes through),
    # so this capability is scoped to ArgoCD specifically rather than to
    # everything sharing that node's network path. Owned by
    # tag:k3s-operator-hetzner (not just autogroup:admin) so the operator's
    # EXISTING OAuth client (hetzner/tailscale/oauth/client, already scoped
    # to tag:k3s-operator-hetzner) can mint tag:argocd-egress keys for the
    # egress proxies it creates via proxyConfig.defaultTags - no second
    # OAuth client needed, this is the same ownership-chain mechanism as
    # Tailscale's own docs example ("tag:k8s": ["tag:k8s-operator"]), not a
    # same-request-must-exactly-match-client-tags constraint as originally
    # assumed (that assumption was wrong - see
    # apps/hetzner-infra/platform/tailscale/values.yaml's comment for the
    # corrected mechanism).
    "tag:argocd-egress" = ["autogroup:admin", "tag:k3s-operator-hetzner"]
  }

  # Hetzner's subnet-router (Connector) needs its own auto-approved route -
  # this cluster's real service CIDR, not the old infra cluster's k3s
  # default (10.43.0.0/16, dropped along with that cluster's connector).
  auto_approvers_routes = {
    "172.21.0.0/16"   = ["tag:k3s-proxy-hetzner"]
    "173.245.48.0/20" = ["tag:exit"]
    "103.21.244.0/22" = ["tag:exit"]
    "103.22.200.0/22" = ["tag:exit"]
    "103.31.4.0/22"   = ["tag:exit"]
    "141.101.64.0/18" = ["tag:exit"]
    "108.162.192.0/18" = ["tag:exit"]
    "190.93.240.0/20" = ["tag:exit"]
    "188.114.96.0/20" = ["tag:exit"]
    "197.234.240.0/22" = ["tag:exit"]
    "198.41.128.0/17" = ["tag:exit"]
    "162.158.0.0/15"  = ["tag:exit"]
    "104.16.0.0/13"   = ["tag:exit"]
    "104.24.0.0/14"   = ["tag:exit"]
    "172.64.0.0/13"   = ["tag:exit"]
    "131.0.72.0/22"   = ["tag:exit"]
    "5.75.242.100/32" = ["tag:exit"]
    "2400:cb00::/32"  = ["tag:exit"]
    "2606:4700::/32"  = ["tag:exit"]
    "2803:f800::/32"  = ["tag:exit"]
    "2405:b500::/32"  = ["tag:exit"]
    "2405:8100::/32"  = ["tag:exit"]
    "2a06:98c0::/29"  = ["tag:exit"]
    "2c0f:f248::/32"  = ["tag:exit"]
  }
  auto_approvers_exit_node = ["tag:exit"]

  grants = [
    {
      # Lets ArgoCD (via its dedicated tag:argocd-egress identity, not yet
      # applied to any device - see hetzner/helm/argocd/argocd/
      # terragrunt.hcl) reach prod-0's and prod-1's Tailscale API server
      # proxy and have the proxy impersonate system:masters for it - the
      # Kubernetes-side ClusterRoleBinding this requires (binding
      # system:masters, or a narrower group, to these proxies'
      # allowImpersonation config) still needs enabling per-cluster; see
      # apps/oracle-prod-0 and apps/oracle-prod-1's tailscale-operator apps.
      # tag:k3s-operator-infra is prod-1's operator tag (legacy name, kept
      # for parity with its existing tag_owners entry).
      src = ["tag:argocd-egress"]
      dst = ["tag:k3s-operator-prod-0", "tag:k3s-operator-infra"]
      app = {
        "tailscale.com/cap/kubernetes" = [
          { impersonate = { groups = ["system:masters"] } }
        ]
      }
    },
    {
      src = ["autogroup:member"]
      dst = ["tag:k3s-proxy-infra", "tag:exit"]
      ip  = ["*"]
    },
    {
      src = ["autogroup:member"]
      dst = ["autogroup:internet"]
      ip  = ["*"]
      via = ["tag:exit"]
    },
    {
      src = ["tag:k3s-proxy-prod-0"]
      dst = ["tag:exit"]
      ip  = ["*"]
    },
    {
      # Lets the Hetzner subnet-router (hostNetwork, --accept-routes) pull
      # in tag:exit's advertised routes (Cloudflare edge ranges + the cas
      # GitLab IP) - a plain destination grant, mirroring the
      # autogroup:member -> 172.21.0.0/16 grant below rather than the
      # via-based exit-node grant above (tag:exit itself has
      # advertise-exit-node=false, so it's a subnet router, not an exit
      # node - via= semantics don't apply to it).
      src = ["tag:k3s-proxy-hetzner"]
      dst = ["autogroup:internet"]
      ip  = ["*"]
      via = ["tag:exit"]
    },
    {
      src = ["tag:k3s-proxy-hetzner"]
      dst = [
        "173.245.48.0/20", "103.21.244.0/22", "103.22.200.0/22", "103.31.4.0/22",
        "141.101.64.0/18", "108.162.192.0/18", "190.93.240.0/20", "188.114.96.0/20",
        "197.234.240.0/22", "198.41.128.0/17", "162.158.0.0/15", "104.16.0.0/13",
        "104.24.0.0/14", "172.64.0.0/13", "131.0.72.0/22", "5.75.242.100/32",
      ]
      ip = ["*"]
    },
    {
      src = ["autogroup:member"]
      dst = ["tag:k3s-proxy-hetzner", "172.21.0.0/16"]
      ip  = ["*"]
    },
  ]
}
