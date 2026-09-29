include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "common" {
  path = "${get_repo_root()}/_common/tailscale/oauth_client.hcl"
}

inputs = {
  # Dedicated client for Connectors/proxies the Hetzner operator provisions
  # (currently just the subnet-router). Separate from
  # hetzner/tailscale/oauth/client (the operator's own): Tailscale requires
  # an authkey request's tags to exactly match the client's whole tag set,
  # and the operator's proxyConfig.defaultTags request (tag:k3s-proxy-hetzner
  # alone) can't share a client with the operator's own tag:k3s-operator-hetzner
  # self-registration.
  description = "hetzner-proxy"
  scopes      = ["devices:core", "auth_keys"]
  tags = [
    "tag:k3s-proxy-hetzner",
  ]
}
