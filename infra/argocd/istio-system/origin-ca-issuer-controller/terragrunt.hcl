include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/argocd/application_set.hcl"
}

dependency "istiod" {
  config_path = "../istiod"
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "output", "init", "destroy"]
  skip_outputs = true
}

inputs = {
  project = "infra"
  apps = [
    {
      helm_chart_version = "0.5.1"
      values = <<EOT
      controller:
        resources:
          limits:
            cpu: 500m
            memory: 500Mi
          requests:
            cpu: 100m
            memory: 50Mi
      certmanager:
        namespace: istio-system
      EOT
    }
  ]
}
