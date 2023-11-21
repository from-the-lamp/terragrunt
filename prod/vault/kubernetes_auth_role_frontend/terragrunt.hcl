include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/vault/kubernetes_auth_role.hcl"
}

inputs = {
  role_name = "frontend-app"
  token_policies = ["frontend-read"]
  service_account_names = ["default"]
  service_account_namespaces = ["frontend"]
}
