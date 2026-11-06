include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "common" {
  path = "${get_repo_root()}/_common/gitlab/group_owner_bot.hcl"
}

# Read-only counterpart to automation/bot (that one is Owner-level and
# drives the gitlab provider itself, including re-applying this very repo's
# units). This bot backs Grafana's "Deployment Control Center" dashboard
# (gitlab-api datasource via yesoreyeram-infinity, listing pipelines/MRs/
# projects group-wide) - scoped down from the module's owner default on
# both axes it exposes: reporter (not owner) group access, read_api (not
# api) token scope. Neither plan nor apply ever needs write access here.
inputs = {
  group              = "from-the-lamp"
  bot_name           = "grafana-reader"
  access_level       = "reporter"
  token_scopes       = ["read_api"]
  rotate_before_days = 3
  expiration_days    = 10
}
