include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "common" {
  path = "${get_repo_root()}/_common/tailscale/oauth_client.hcl"
}

inputs = {
  # Tailscale requires an OAuth client's authkey request tags to exactly
  # match the client's whole configured tag set, so this needs its own
  # client scoped to just tag:k8s-operator-homelab (the operator's own
  # operatorConfig.defaultTags), not shared with tag:k8s-proxy-homelab
  # (see proxy-client below).
  #
  # tag:k3s-operator-homelab renamed to tag:k8s-operator-homelab
  # (infra/tailscale/acl) - "k8s" not "k3s" since this identifies the
  # operator, not the k8s distro behind it (Talos here). MUST be applied
  # together with apps/homelab/platform/tailscale's
  # operatorConfig.defaultTags - see infra/tailscale/oauth/client's
  # matching comment for why a mismatch breaks the operator's authkey
  # request entirely.
  description = "homelab-operator"
  scopes      = ["devices:core", "auth_keys"]
  tags = [
    "tag:k8s-operator-homelab",
  ]
}
