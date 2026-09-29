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
  }

  # Hetzner's subnet-router (Connector) needs its own auto-approved route -
  # this cluster's real service CIDR, not the old infra cluster's k3s
  # default (10.43.0.0/16, dropped along with that cluster's connector).
  auto_approvers_routes = {
    "10.96.0.0/12"    = ["tag:k3s-proxy-hetzner"]
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
      src = ["autogroup:member"]
      dst = ["tag:k3s-proxy-hetzner", "10.96.0.0/12"]
      ip  = ["*"]
    },
  ]
}
