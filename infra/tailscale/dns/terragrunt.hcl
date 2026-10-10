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
      # The homelab cluster's own apps live under this subdomain
      # specifically so this entry can be MORE SPECIFIC than the
      # "internal.from-the-lamp.work" entry above (Tailscale split-DNS
      # resolves by longest-match domain, so this one wins for anything
      # under it) - without a distinct, separately-delegated subdomain,
      # homelab's apps would resolve via Hetzner's resolver instead of their
      # own, since both clusters can't share one delegation for the same
      # name. PLACEHOLDER - address is homelab's own private-resolver
      # CoreDNS ClusterIP (apps/homelab/platform/coredns, lamp-coredns),
      # which is auto-assigned and unknowable until that app's Service
      # actually exists - see apps/homelab/platform/kube-system/templates/
      # coredns-internal-domain.yaml for the matching in-cluster forward
      # target that needs the same real value once known.
      domain = "homelab.internal.from-the-lamp.work"
      nameservers = [
        { address = "172.25.189.156", use_with_exit_node = true },
      ]
    },
  ]
}
