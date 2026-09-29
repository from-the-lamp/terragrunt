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
    "10.96.0.0/12" = ["tag:k3s-proxy-hetzner"]
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
