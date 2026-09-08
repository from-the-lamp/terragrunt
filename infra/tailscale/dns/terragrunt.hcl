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
      domain = "internal.from-the-lamp.work"
      nameservers = [
        { address = "10.43.148.0", use_with_exit_node = true },
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
