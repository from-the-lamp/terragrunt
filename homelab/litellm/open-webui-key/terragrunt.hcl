include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "common" {
  path = "${get_repo_root()}/_common/litellm/virtual_key.hcl"
}

inputs = {
  key_alias         = "open-webui"
  vault_secret_path = "litellm"
  vault_property    = "open_webui_api_key"
  max_budget        = 20
  budget_duration   = "30d"
}
