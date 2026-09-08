include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "common" {
  path = "${get_repo_root()}/_common/tailscale/oauth_client.hcl"
}

inputs = {
  description = "infra-operator"
  scopes      = ["devices:core", "auth_keys"]
  tags = [
    "tag:k3s-operator-infra",
    "tag:k3s-proxy-infra",
    "tag:exit",
  ]
}
