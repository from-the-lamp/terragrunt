include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/k8s/helm.hcl"
}

locals {
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  dns_zone_name = local.environment_vars.locals.dns_zone_name
}

dependency "argo-cd" {
  config_path = "../argo-cd"
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "output", "init", "destroy"]
  skip_outputs = true
}

inputs = {
  helm_chart_name = "istio-gateway"
  helm_chart_version = "0.0.3" 
  helm_values_file = <<-EOF
  hosts:
  - argocd.${local.dns_zone_name}
  external: true
  virtualService:
    destination:
      host: argo-cd-argocd-server
      port: 80
  EOF
}
