include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/k8s/helm.hcl"
}

dependency "origin-ca-issuer" {
  config_path  = "../origin-ca-issuer"
  skip_outputs = true
}

dependency "get_infra_variables" {
  config_path = "../../../gitlab/get_infra_variables"
  mock_outputs_allowed_terraform_commands = ["apply", "plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    "map_variables.cloudflare_originCAissuerKey" = "fake-key"
  }
}

inputs = {
  helm_local_repo       = true
  helm_addition_setting = {
    originCAissuerKey   =  dependency.get_infra_variables.outputs.map_variables.cloudflare_originCAissuerKey
  }
}
