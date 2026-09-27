include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "common" {
  path = "${get_repo_root()}/_common/tailscale/dns.hcl"
}

inputs = {
  magic_dns          = true
  override_local_dns = true

  global_nameservers = [
    { address = "8.8.8.8" },
    { address = "1.1.1.1" },
    { address = "1.0.0.1" },
  ]

  split_dns = [
    {
      # Moved from the old "infra" k3s cluster (10.43.148.0, its
      # private-resolver CoreDNS ClusterIP) to Hetzner's own private-resolver
      # - that cluster now serves *.internal.from-the-lamp.work.
      domain = "internal.from-the-lamp.work"
      nameservers = [
        { address = "10.107.125.196", use_with_exit_node = true },
      ]
    },
    {
      domain = "internal.from-the-lamp.com"
      nameservers = [
        { address = "10.43.93.137", use_with_exit_node = true },
      ]
    },
  ]
}
