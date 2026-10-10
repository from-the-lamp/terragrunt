include "root" {
  path = find_in_parent_folders("root.hcl")
}

# Not Hetzner-specific at all - just talos_version from env.hcl - reused as-is.
include "common" {
  path = "${get_repo_root()}/_common/talos/secrets.hcl"
}
