include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "common" {
  path = "${get_repo_root()}/_common/tailscale/oauth_client.hcl"
}

inputs = {
  description = "infra-operator"
  scopes      = ["devices:core", "auth_keys"]
  # Just the operator's own tag. Tailscale rejects an OAuth-client authkey
  # request unless the requested tags are an EXACT match of the client's
  # whole configured tag set, not a subset (confirmed by direct API testing)
  # - the k8s-operator's tsnet self-registration requests only
  # operatorConfig.defaultTags (this one tag), so bundling k3s-proxy-infra/
  # tag:exit/hetzner's tags in here as before made every one of those
  # requests fail, including this tag itself. Hetzner now has its own
  # dedicated client (hetzner/tailscale/oauth/client) instead of sharing
  # this one; tag:exit gets its own client too (../oauth/exit-client) for
  # the same reason.
  tags = [
    "tag:k3s-operator-infra",
  ]
}
