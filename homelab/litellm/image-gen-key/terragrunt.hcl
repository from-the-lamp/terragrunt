include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "common" {
  path = "${get_repo_root()}/_common/litellm/virtual_key.hcl"
}

inputs = {
  key_alias         = "image-gen"
  vault_secret_path = "litellm"
  vault_property    = "image_gen_api_key"
  models            = ["gemini-2.5-flash-image"]
  max_budget        = 10
  budget_duration   = "30d"
}
