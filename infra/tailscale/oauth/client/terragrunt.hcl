include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "common" {
  path = "${get_repo_root()}/_common/tailscale/oauth_client.hcl"
}

inputs = {
  description = "prod-1-operator"
  scopes      = ["devices:core", "auth_keys"]
  # Just the operator's own tag. Tailscale rejects an OAuth-client authkey
  # request unless the requested tags are an EXACT match of the client's
  # whole configured tag set, not a subset (confirmed by direct API testing)
  # - the k8s-operator's tsnet self-registration requests only
  # operatorConfig.defaultTags (this one tag), so bundling tag:k8s-proxy-
  # prod-1/tag:exit/hetzner's tags in here as before made every one of
  # those requests fail, including this tag itself. Hetzner's own
  # dedicated client is gone along with that cluster; tag:exit gets its
  # own client too (../oauth/exit-client) for the same reason.
  #
  # tag:k3s-operator-infra renamed to tag:k8s-operator-prod-1
  # (infra/tailscale/acl) - "k8s" not "k3s" since this identifies the
  # operator, not the k8s distro behind it, and "prod-1" not "infra" to
  # match this cluster's actual name everywhere else. MUST be applied
  # together with apps/oracle-prod-1/platform/tailscale-operator's
  # operatorConfig.defaultTags - an exact-match mismatch between this
  # list and what the operator requests breaks its authkey request
  # entirely (see comment above), which would leave ArgoCD unable to
  # re-establish its Tailscale API server proxy connection to this
  # cluster until both sides agree again.
  tags = [
    "tag:k8s-operator-prod-1",
  ]
}
