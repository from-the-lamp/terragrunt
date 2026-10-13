include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "common" {
  path = "${get_repo_root()}/_common/tailscale/oauth_client.hcl"
}

inputs = {
  # Mirrors hetzner/tailscale/oauth/proxy-client: the subnet-router hostNode
  # (apps/homelab/platform/tailscale's lamp-tailscale-nodes) needs its own
  # OAuth client scoped to tag:k3s-proxy-homelab alone - it can't share the
  # operator's own client (tag:k3s-operator-homelab) for the same
  # exact-tag-match reason documented there. Its client_secret is used
  # directly as TS_AUTHKEY (see tailscale-subnet-router-auth ExternalSecret,
  # Vault key "tailscale-proxy-homelab"), not CLIENT_ID_FILE/CLIENT_SECRET_FILE.
  description = "homelab-proxy"
  scopes      = ["devices:core", "auth_keys"]
  tags = [
    "tag:k3s-proxy-homelab",
  ]
}
