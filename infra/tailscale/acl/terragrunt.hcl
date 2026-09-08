include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "common" {
  path = "${get_repo_root()}/_common/tailscale/acl.hcl"
}

inputs = {
  overwrite_existing_content = true

  tag_owners = {
    "tag:exit"               = ["autogroup:admin"]
    "tag:k3s-operator-infra" = ["autogroup:admin"]
    "tag:k3s-proxy-infra"    = ["autogroup:admin"]
  }

  auto_approvers_routes = {
    "10.43.0.0/16" = ["tag:k3s-proxy-infra"]
  }
  auto_approvers_exit_node = ["tag:exit"]

  grants = [
    {
      src = ["autogroup:member"]
      dst = ["tag:k3s-proxy-infra", "tag:exit", "10.43.0.0/16"]
      ip  = ["*"]
    },
    {
      src = ["autogroup:member"]
      dst = ["autogroup:internet"]
      ip  = ["*"]
      via = ["tag:exit"]
    },
  ]
}
