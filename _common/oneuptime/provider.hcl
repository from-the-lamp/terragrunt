# Shared across all homelab/oneuptime/* units - was copy-pasted verbatim
# into each unit's terragrunt.hcl (5 identical copies, confirmed via
# FTL-223 audit). Only the provider block is shared here, not
# terraform.source: unlike _common/litellm/virtual_key.hcl, these modules
# aren't published to infra/modules yet (still local-only under the
# gitignored _modules/oneuptime/*), so each unit keeps its own
# terraform.source pointing at its own module directory.
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "vault" {
  address = "${get_env("VAULT_ADDR")}"
  token   = "${get_env("VAULT_TOKEN")}"
}

data "vault_kv_secret_v2" "oneuptime_creds" {
  mount = "platform"
  name  = "oneuptime"
}

provider "oneuptime" {
  oneuptime_url = "https://oneuptime.from-the-lamp.work"
  api_key       = data.vault_kv_secret_v2.oneuptime_creds.data["api-key"]
}
EOF
}
