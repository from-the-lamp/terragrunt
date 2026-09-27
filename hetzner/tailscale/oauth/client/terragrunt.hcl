include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "common" {
  path = "${get_repo_root()}/_common/tailscale/oauth_client.hcl"
}

inputs = {
  # Dedicated client for Hetzner rather than reusing infra/tailscale/oauth's
  # shared "infra-operator" client. Root cause (confirmed via direct API
  # testing, not guessed): Tailscale requires an OAuth-client authkey
  # request's tags to be an EXACT match of the client's full configured tag
  # set, not a subset - requesting just one of several configured tags is
  # rejected as "invalid or not permitted" even though that tag is in the
  # client's own scope. The k8s-operator's own tsnet identity requests only
  # operatorConfig.defaultTags (here, tag:k3s-operator-hetzner alone), so
  # this client is scoped to that single tag - not also tag:k3s-proxy-hetzner
  # (proxyConfig.defaultTags is a separate concern; see proxy client below
  # if the operator turns out to need its own credential for that path too).
  description = "hetzner-operator"
  scopes      = ["devices:core", "auth_keys"]
  tags = [
    "tag:k3s-operator-hetzner",
  ]
}
