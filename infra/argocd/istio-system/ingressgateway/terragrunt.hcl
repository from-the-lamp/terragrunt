include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/argocd/application_set.hcl"
}

locals {
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env = local.environment_vars.locals.environment
}

dependency "istiod" {
  config_path = "../istiod"
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "output", "init", "destroy"]
  skip_outputs = true
}

dependency "allow_https_from_all" {
  config_path = "${get_repo_root()}/${local.env}/oracle/nsg/allow_https_from_all"
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    id = "fake-id"
  }
}

inputs = {
  project = "infra"
  apps = [
    { 
      helm_chart_name = "gateway"
      helm_repo_url = "https://istio-release.storage.googleapis.com/charts"
      helm_chart_version = "1.20.0"
      values = <<EOT
      kind: DaemonSet
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: node-role
                operator: In
                values:
                - "worker"
      service:
        externalTrafficPolicy: Local
        annotations:
          oci.oraclecloud.com/load-balancer-type: "nlb"
          oci-network-load-balancer.oraclecloud.com/is-preserve-source: "false"
          oci-network-load-balancer.oraclecloud.com/node-label-selector: "node-role=worker"
          oci-network-load-balancer.oraclecloud.com/security-list-management-mode: "All"
        ports:
        - name: status-port
          port: 15021
          protocol: TCP
          targetPort: 15021
        - name: https
          port: 443
          protocol: TCP
          targetPort: 443
      EOT
    }
  ]
}
