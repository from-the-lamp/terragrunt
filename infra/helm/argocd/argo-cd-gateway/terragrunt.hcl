include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/k8s/helm.hcl"
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
  - argocd.from-the-lamp.work
  external: true
  virtualService:
    destination:
      host: argo-cd-argocd-server
      port: 80
  EOF
}
