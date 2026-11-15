include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "common" {
  path = "${get_repo_root()}/_common/tailscale/acl.hcl"
}

inputs = {
  overwrite_existing_content = true

  tag_owners = {
    "tag:exit" = ["autogroup:admin"]
    # "k8s" rather than "k3s" - these identify a cluster's own
    # tailscale-operator/its default egress proxies, not the specific k8s
    # distro behind it (which varies: k3s on Oracle, Talos on homelab).
    # prod-1's pair used to be named "...-infra" (legacy - the cluster was
    # called "infra" before oracle-prod-0/oracle-prod-1 naming settled;
    # terraform/terragrunt's own directory layout still reflects that old
    # name, out of scope for this rename).
    "tag:k8s-operator-prod-0" = ["autogroup:admin"]
    "tag:k8s-proxy-prod-0"    = ["autogroup:admin"]
    "tag:k8s-operator-prod-1" = ["autogroup:admin"]
    "tag:k8s-proxy-prod-1"    = ["autogroup:admin"]
    # homelab's own tailscale-operator (ArgoCD relocation) and its existing
    # subnet-router hostNode (apps/homelab/platform/tailscale) - the latter
    # was already referencing this tag before it was ever declared here.
    "tag:k8s-operator-homelab" = ["autogroup:admin"]
    "tag:k8s-proxy-homelab"    = ["autogroup:admin"]
    # Dedicated identity for ArgoCD's own connection to prod-0/prod-1's
    # Tailscale API server proxy - ownership-chain minting, same mechanism
    # as Tailscale's own docs example ("tag:k8s": ["tag:k8s-operator"]).
    "tag:argocd-egress" = ["autogroup:admin", "tag:k8s-operator-homelab"]
    # The webhook-relay identity (banking-callback's public hook, routed
    # through Oracle prod-0/1 - see apps/oracle-prod-0/platform/
    # webhook-relay and apps/homelab/platform/tailscale's new Ingresses).
    # Ingress side: owned by homelab's operator so it can mint tags for the
    # two Ingress-backed devices (tailscale.com/tags annotation). Egress
    # side: owned by both Oracle operators so either region's relay proxy
    # can mint it for its own egress Service.
    "tag:webhook-relay-ingress" = ["tag:k8s-operator-homelab"]
    "tag:webhook-relay-egress"  = ["tag:k8s-operator-prod-0", "tag:k8s-operator-prod-1"]
    # Dedicated identity for toolhive's oracle-0/oracle-1 kubernetes
    # MCP servers to reach prod-0/prod-1's Tailscale API server proxy -
    # same mechanism as tag:argocd-egress above, kept as its own tag rather
    # than reusing argocd-egress so this capability is independently
    # auditable/revocable from ArgoCD's own. Owned by tag:k8s-operator-homelab
    # so homelab's existing operator OAuth client can mint it for the
    # dedicated ProxyGroup (apps/homelab/platform/tailscale) backing the
    # prod-0/1-k8s-operator-toolhive egress Services.
    "tag:toolhive-egress" = ["tag:k8s-operator-homelab"]
    # Oracle prod-0/1's vmagent (lamp-victoria-metrics-agent) pushing metrics
    # into homelab's vminsert over the tailnet - same egress/ingress shape as
    # tag:webhook-relay-{egress,ingress} just reversed in purpose, kept as its
    # own pair rather than reusing that one so it's independently auditable/
    # revocable (same reasoning as tag:toolhive-egress vs tag:argocd-egress
    # above). Ingress side owned by homelab's operator (mints it for the new
    # vminsert-tailnet Service, apps/homelab/platform/tailscale); egress side
    # owned by both Oracle operators (mints it for each cluster's own
    # ProxyGroup, apps/oracle-prod-0|1/platform/tailscale-operator).
    "tag:victoria-metrics-ingress" = ["tag:k8s-operator-homelab"]
    "tag:victoria-metrics-egress"  = ["tag:k8s-operator-prod-0", "tag:k8s-operator-prod-1"]
    # litellm (homelab) reaching djinn's Windows PC running LM Studio -
    # same egress/ingress shape as tag:webhook-relay-{egress,ingress}, kept
    # as its own pair for the same independently-auditable/revocable
    # reasoning. Scoped to the LM Studio API port ONLY - scraping that same
    # PC's windows_exporter is a different purpose/consumer (vmagent, not
    # litellm), so it goes through tag:metrics-egress below instead of
    # being folded in here. Egress side owned by homelab's operator (mints
    # it for the dedicated ProxyGroup, apps/homelab/platform/tailscale).
    # Ingress side owned by autogroup:admin only - the Windows PC is djinn's
    # own pre-existing tailnet device, not something an operator
    # provisions, so the tag has to be applied by hand in the admin console
    # (Machines -> desktop-uid8gr9 -> Edit ACL tags) rather than minted
    # automatically.
    "tag:lmstudio-egress"  = ["tag:k8s-operator-homelab"]
    "tag:lmstudio-ingress" = ["autogroup:admin"]
    # vmagent (homelab) scraping metrics exporters on djinn's own tailnet
    # devices - windows_exporter on the Windows PC (tag:lmstudio-ingress,
    # already applied to that device for the grant above - a second grant
    # below reuses it as a destination without folding into
    # tag:lmstudio-egress, so monitoring access stays independently
    # revocable from litellm's LLM-API access) and node_exporter on
    # macbook-djinn-1 (by IP, not a tag - see the grant below).
    # Deliberately NO matching ingress tag for the macbook case: unlike the
    # Windows PC (a dedicated device with no autogroup:member traffic of
    # its own), macbook-djinn-1 is djinn's daily-driver laptop - tagging a
    # device that's normally autogroup:member drops it out of every
    # "src = autogroup:member" grant in this file (confirmed live: it
    # immediately lost visibility of every other peer in `tailscale
    # status`, same mechanism as this file's "didn't even appear in
    # tailscale status" comment elsewhere, just the reverse direction - the
    # newly-tagged device losing its OWN autogroup:member-derived src
    # grants, not others losing sight of it).
    "tag:metrics-egress" = ["tag:k8s-operator-homelab"]
    # Leftover from an earlier (abandoned) approach: macbook-djinn-1 was
    # briefly tagged tag:node-exporter-ingress to let vmagent reach it,
    # before the grant below was switched to target it by IP instead (see
    # tag:metrics-egress's comment above) - at which point this tag
    # stopped being functionally needed. Tailscale has no way to clear ALL
    # tags from a device without reauthenticating it (which would change
    # its identity/key), so rather than force that, this tag stays
    # declared and gets added alongside autogroup:member in this file's
    # member-scoped grants below, restoring this device's normal
    # connectivity while it keeps carrying the tag.
    "tag:node-exporter-ingress" = ["autogroup:admin"]
  }

  auto_approvers_routes = {
    # homelab's subnet-router (apps/homelab/platform/tailscale hostNode)
    # advertises this - without an auto-approver entry it'd sit pending
    # manual approval in the admin console, blocking Tailscale reachability
    # to homelab entirely (including the relocated ArgoCD's own UI).
    "172.25.0.0/16" = ["tag:k8s-proxy-homelab"]
    # homelab's LAN subnet - same subnet-router, added so the node itself
    # (kube-apiserver/Talos API) is reachable over Tailscale, not just
    # in-cluster services.
    "192.168.8.0/24"   = ["tag:k8s-proxy-homelab"]
    "173.245.48.0/20"  = ["tag:exit"]
    "103.21.244.0/22"  = ["tag:exit"]
    "103.22.200.0/22"  = ["tag:exit"]
    "103.31.4.0/22"    = ["tag:exit"]
    "141.101.64.0/18"  = ["tag:exit"]
    "108.162.192.0/18" = ["tag:exit"]
    "190.93.240.0/20"  = ["tag:exit"]
    "188.114.96.0/20"  = ["tag:exit"]
    "197.234.240.0/22" = ["tag:exit"]
    "198.41.128.0/17"  = ["tag:exit"]
    "162.158.0.0/15"   = ["tag:exit"]
    "104.16.0.0/13"    = ["tag:exit"]
    "104.24.0.0/14"    = ["tag:exit"]
    "172.64.0.0/13"    = ["tag:exit"]
    "131.0.72.0/22"    = ["tag:exit"]
    "5.75.242.100/32"  = ["tag:exit"]
    "2400:cb00::/32"   = ["tag:exit"]
    "2606:4700::/32"   = ["tag:exit"]
    "2803:f800::/32"   = ["tag:exit"]
    "2405:b500::/32"   = ["tag:exit"]
    "2405:8100::/32"   = ["tag:exit"]
    "2a06:98c0::/29"   = ["tag:exit"]
    "2c0f:f248::/32"   = ["tag:exit"]
  }
  auto_approvers_exit_node = ["tag:exit"]

  grants = [
    {
      # Lets ArgoCD (via its dedicated tag:argocd-egress identity) reach
      # prod-0's and prod-1's Tailscale API server proxy and have the
      # proxy impersonate system:masters for it - the Kubernetes-side
      # ClusterRoleBinding this requires (binding system:masters, or a
      # narrower group, to these proxies' allowImpersonation config) still
      # needs enabling per-cluster; see apps/oracle-prod-0 and
      # apps/oracle-prod-1's tailscale-operator apps.
      src = ["tag:argocd-egress"]
      dst = ["tag:k8s-operator-prod-0", "tag:k8s-operator-prod-1"]
      # ip is required alongside app: app only grants the impersonation
      # capability the API server proxy consults AFTER a connection is
      # already established - the raw TCP handshake on 443 is a separate,
      # network-level permission. Without this, tailscaled on the
      # destination rejects the connection outright ("rejected due to acl"
      # in the proxy's own logs), never reaching the point where the app
      # capability would even be consulted. Confirmed live: adding the
      # tag:argocd-egress identity without this field got exactly that
      # rejection from both prod-0-k8s-operator and prod-1-k8s-operator.
      ip = ["443"]
      app = {
        "tailscale.com/cap/kubernetes" = [
          { impersonate = { groups = ["system:masters"] } }
        ]
      }
    },
    {
      # toolhive's oracle-0/oracle-1 MCP servers - same shape as the
      # tag:argocd-egress grant above (ip=443 required alongside app for the
      # same reason: the raw TCP handshake is checked before the
      # impersonation capability is ever consulted).
      src = ["tag:toolhive-egress"]
      dst = ["tag:k8s-operator-prod-0", "tag:k8s-operator-prod-1"]
      ip  = ["443"]
      app = {
        "tailscale.com/cap/kubernetes" = [
          { impersonate = { groups = ["system:masters"] } }
        ]
      }
    },
    {
      # tag:node-exporter-ingress included alongside autogroup:member -
      # see that tag's tag_owners comment: macbook-djinn-1 still carries
      # it (Tailscale can't fully untag a device without reauthenticating
      # it), so it needs the same member-equivalent grants explicitly.
      src = ["autogroup:member", "tag:node-exporter-ingress"]
      dst = ["tag:k8s-proxy-prod-1", "tag:exit"]
      ip  = ["*"]
    },
    {
      src = ["autogroup:member", "tag:node-exporter-ingress"]
      dst = ["autogroup:internet"]
      ip  = ["*"]
      via = ["tag:exit"]
    },
    {
      src = ["tag:k8s-proxy-prod-0"]
      dst = ["tag:exit"]
      ip  = ["*"]
    },
    {
      # Lets homelab's subnet-router (hostNetwork, --accept-routes) pull in
      # tag:exit's advertised routes (Cloudflare edge ranges + the cas
      # GitLab IP) - a plain destination grant, mirroring the
      # autogroup:member -> 172.25.0.0/16 grant below rather than the
      # via-based exit-node grant above (tag:exit itself has
      # advertise-exit-node=false, so it's a subnet router, not an exit
      # node - via= semantics don't apply to it). Without this, toolhive's
      # gitlab-cas-dev/gitlab-cas-gitops MCP servers egress on homelab's
      # own ISP IP instead of the Cloudflare-allowlisted one, and
      # v-soft.dev/v-gitops.cc's Cloudflare in front of them returns a bare
      # 403 "Sorry, you have been blocked".
      src = ["tag:k8s-proxy-homelab"]
      dst = ["autogroup:internet"]
      ip  = ["*"]
      via = ["tag:exit"]
    },
    {
      src = ["tag:k8s-proxy-homelab"]
      dst = [
        "173.245.48.0/20", "103.21.244.0/22", "103.22.200.0/22", "103.31.4.0/22",
        "141.101.64.0/18", "108.162.192.0/18", "190.93.240.0/20", "188.114.96.0/20",
        "197.234.240.0/22", "198.41.128.0/17", "162.158.0.0/15", "104.16.0.0/13",
        "104.24.0.0/14", "172.64.0.0/13", "131.0.72.0/22", "5.75.242.100/32",
      ]
      ip = ["*"]
    },
    {
      # Without this, tailnet members have no ACL path to homelab's
      # subnet-router or its advertised 172.25.0.0/16 route at all
      # (confirmed live: the device didn't even appear in `tailscale
      # status`, and DNS queries forwarded to its private-resolver
      # ClusterIP 172.25.80.94 timed out rather than SERVFAIL-ing).
      src = ["autogroup:member", "tag:node-exporter-ingress"]
      dst = ["tag:k8s-proxy-homelab", "172.25.0.0/16", "192.168.8.0/24"]
      ip  = ["*"]
    },
    {
      # Oracle prod-0/1's webhook-relay egress proxies reaching homelab's
      # webhook-relay Service (banking-callback :80) - this is a plain L4
      # tailscale.com/expose Service (not the K8s-API-proxy case above), so
      # unlike tag:argocd-egress there's no single fixed port to pin;
      # ip=["*"] is safe since src/dst already narrow this to exactly the
      # two tag groups. Confirmed live: ip=["443"] produced "rejected due
      # to acl" on the real port (80).
      src = ["tag:webhook-relay-egress"]
      dst = ["tag:webhook-relay-ingress"]
      ip  = ["*"]
    },
    {
      # Oracle prod-0/1's vmagent reaching homelab's vminsert (single fixed
      # port, unlike the webhook-relay grant above which spans two different
      # Services on two different ports).
      src = ["tag:victoria-metrics-egress"]
      dst = ["tag:victoria-metrics-ingress"]
      ip  = ["8480"]
    },
    {
      # litellm's dedicated egress ProxyGroup reaching LM Studio's OpenAI-
      # compatible server on djinn's Windows PC - single fixed port, same
      # shape as the victoria-metrics grant above. Requires the PC to
      # actually be tagged tag:lmstudio-ingress in the admin console
      # (tag_owners comment above) before this has anything to match.
      src = ["tag:lmstudio-egress"]
      dst = ["tag:lmstudio-ingress"]
      ip  = ["1234"]
    },
    {
      # vmagent's dedicated egress ProxyGroup (apps/homelab/platform/
      # tailscale) scraping windows_exporter on the same Windows PC as the
      # lmstudio grant above - same destination tag (already applied to
      # that device), different src identity on purpose, so monitoring
      # access stays independently revocable from litellm's own.
      src = ["tag:metrics-egress"]
      dst = ["tag:lmstudio-ingress"]
      ip  = ["9182"]
    },
    {
      # Same egress ProxyGroup reaching node_exporter on djinn's own
      # daily-driver laptop - targeted by its tailnet IP, not a tag (see
      # tag_owners comment above: tagging this device instead would pull
      # it out of every autogroup:member grant it currently relies on for
      # its own normal connectivity). Update this IP if macbook-djinn-1 is
      # ever re-registered on the tailnet (`tailscale ip -4` to check).
      src = ["tag:metrics-egress"]
      dst = ["100.109.236.52/32"]
      ip  = ["9100"]
    },
    {
      # djinn's own devices reaching the Windows PC's ComfyUI web UI
      # directly - same tagged device as tag:lmstudio-ingress above, port
      # 8188 (ComfyUI's --listen 0.0.0.0 bind). Without this grant the
      # device doesn't even appear in `tailscale status` for other tailnet
      # members, same symptom as the homelab subnet-router case elsewhere
      # in this file.
      src = ["autogroup:member", "tag:node-exporter-ingress"]
      dst = ["tag:lmstudio-ingress"]
      ip  = ["8188"]
    },
  ]
}
