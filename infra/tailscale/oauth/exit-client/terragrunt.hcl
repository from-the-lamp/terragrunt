include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "common" {
  path = "${get_repo_root()}/_common/tailscale/oauth_client.hcl"
}

inputs = {
  # Dedicated client for the infra cluster's exit-node hostNode
  # (lamp-tailscale-nodes, TS_AUTHKEY built from this client's own secret -
  # see hostnode-auth.yaml). Kept separate from ../client (the operator's)
  # rather than bundling tag:exit into that one, since Tailscale requires an
  # OAuth-client authkey request's tags to exactly match the client's whole
  # tag set - a shared multi-tag client can't satisfy the operator's
  # single-tag self-registration AND this hostNode's single tag:exit at once.
  description = "infra-exit-node"
  scopes      = ["devices:core", "auth_keys"]
  tags = [
    "tag:exit",
  ]
}
