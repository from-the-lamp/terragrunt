include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "common" {
  path = "${get_repo_root()}/_common/litellm/virtual_key.hcl"
}

inputs = {
  key_alias         = "mosaic"
  vault_secret_path = "litellm"
  vault_property    = "mosaic_api_key"
  models            = ["gemini-2.5-flash-image", "gemini-3-pro-image", "gpt-5.6-terra", "gemma-4-26b-a4b-it"]
  max_budget        = 20
  budget_duration   = "30d"
}
