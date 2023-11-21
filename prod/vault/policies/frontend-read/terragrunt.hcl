include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/vault/policy.hcl"
}

inputs = {
  policy_value = <<EOT
  path "secrets/*" {
    capabilities = ["read"]
  }
  EOT
}
