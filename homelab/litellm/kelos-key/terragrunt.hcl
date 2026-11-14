include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "common" {
  path = "${get_repo_root()}/_common/litellm/virtual_key.hcl"
}

inputs = {
  key_alias         = "kelos"
  vault_secret_path = "litellm"
  vault_property    = "kelos_api_key"
  # No budget, unlike this module's other callers - this key is shared by
  # every Kelos agent in the cluster (taskspawner-alertmanager.yaml:156-160
  # explains why a litellm-level cap was deliberately never put on
  # kelos-openai-key: it would throttle all of them, not just one flow).
}
