include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "common" {
  path = "${get_repo_root()}/_common/tailscale/oauth_client.hcl"
}

inputs = {
  # The subnet-router hostNode (apps/homelab/platform/tailscale's
  # lamp-tailscale-nodes) needs its own OAuth client scoped to
  # tag:k8s-proxy-homelab alone - it can't share the operator's own client
  # (tag:k8s-operator-homelab) for the same exact-tag-match reason
  # documented in ../client's terragrunt.hcl. Its client_secret is used
  # directly as TS_AUTHKEY (see tailscale-subnet-router-auth ExternalSecret,
  # Vault key "tailscale-proxy-homelab"), not CLIENT_ID_FILE/CLIENT_SECRET_FILE.
  #
  # tag:k3s-proxy-homelab renamed to tag:k8s-proxy-homelab
  # (infra/tailscale/acl) - MUST be applied together with
  # apps/homelab/platform/tailscale's hostNodes[].tags for the same
  # exact-match reason as ../client's terragrunt.hcl.
  description = "homelab-proxy"
  scopes      = ["devices:core", "auth_keys"]
  tags = [
    "tag:k8s-proxy-homelab",
  ]
}
