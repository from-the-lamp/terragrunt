include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/argocd/application_set.hcl"
}

dependency "crossplane" {
  config_path = "../crossplane"
  mock_outputs_allowed_terraform_commands = ["apply", "plan", "validate", "output", "init", "destroy"]
  skip_outputs = true
}

inputs = {
  apps = [
    {
      helm_chart_version = "0.0.2"
    }
  ]
}
