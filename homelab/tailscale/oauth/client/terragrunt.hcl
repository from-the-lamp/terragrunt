include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "common" {
  path = "${get_repo_root()}/_common/tailscale/oauth_client.hcl"
}

inputs = {
  # Mirrors hetzner/tailscale/oauth/client: Tailscale requires an OAuth
  # client's authkey request tags to exactly match the client's whole
  # configured tag set, so this needs its own client scoped to just
  # tag:k3s-operator-homelab (the operator's own operatorConfig.defaultTags),
  # not shared with tag:k3s-proxy-homelab (see proxy-client below, mirroring
  # hetzner/tailscale/oauth/proxy-client, if the subnet-router also needs its
  # own dedicated credential).
  description = "homelab-operator"
  scopes      = ["devices:core", "auth_keys"]
  tags = [
    "tag:k3s-operator-homelab",
  ]
}
