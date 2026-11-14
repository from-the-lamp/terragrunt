include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "common" {
  path = "${get_repo_root()}/_common/litellm/virtual_key.hcl"
}

inputs = {
  key_alias         = "hermes-djinn"
  vault_secret_path = "litellm"
  vault_property    = "hermes_djinn_api_key"
  max_budget        = 20
  budget_duration   = "30d"
}
