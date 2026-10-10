include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "common" {
  path = "${get_repo_root()}/_common/tailscale/dns.hcl"
}

inputs = {
  magic_dns          = true
  override_local_dns = false

  global_nameservers = [
    { address = "8.8.8.8" },
    { address = "1.1.1.1" },
    { address = "1.0.0.1" },
  ]

  split_dns = [
    {
      # Moved from the old "infra" k3s cluster (10.43.148.0, its
      # private-resolver CoreDNS ClusterIP) to Hetzner's own private-resolver
      # - that cluster now serves *.internal.from-the-lamp.work. IP updated
      # again after the Hetzner cluster's service CIDR moved to
      # 172.21.0.0/16 (external-dns-private-resolver's auto-assigned
      # ClusterIP changed along with it).
      domain = "internal.from-the-lamp.work"
      nameservers = [
        { address = "172.21.189.156", use_with_exit_node = true },
      ]
    },
    {
      domain = "internal.from-the-lamp.com"
      nameservers = [
        { address = "10.43.93.137", use_with_exit_node = true },
      ]
    },
    {
      # Deliberately the bare apex, not a homelab-specific subdomain - this
      # is a "cutover" domain scheme: homelab's apps answer under the same
      # names Hetzner's own public gateway serves publicly
      # (*.from-the-lamp.work), and for tailnet members THIS entry makes
      # homelab's resolver authoritative instead of real public DNS. It
      # doesn't conflict with the "internal.from-the-lamp.work" entry above
      # despite being its parent domain - that entry still wins by
      # longest-match for anything under "internal.", this one only
      # catches names that aren't. Any given app name is effectively taken
      # away from Hetzner for tailnet clients once homelab's version of it
      # exists and answers here - see infra/argo-apps's
      # apps/homelab/platform/README.md for which names already collide
      # live (windmill.from-the-lamp.work, currently Hetzner's public
      # Slack-webhook route). PLACEHOLDER - address is homelab's own
      # private-resolver CoreDNS ClusterIP (apps/homelab/platform/coredns,
      # lamp-coredns), auto-assigned and unknowable until that app's
      # Service actually exists - see apps/homelab/platform/kube-system/
      # templates/coredns-internal-domain.yaml for the matching in-cluster
      # forward target that needs the same real value once known.
      domain = "from-the-lamp.work"
      nameservers = [
        { address = "172.25.189.156", use_with_exit_node = true },
      ]
    },
  ]
}
