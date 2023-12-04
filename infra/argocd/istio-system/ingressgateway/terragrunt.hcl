include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/argocd/application_set.hcl"
}

locals {
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env = local.environment_vars.locals.environment
  common_settings = read_terragrunt_config("${get_repo_root()}/terragrunt.hcl")
  versions = read_terragrunt_config("${get_repo_root()}/_common/versions.hcl")
  istio_system_version = local.versions.locals.istio_system
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

dependency "allow_https_from_all_prod" {
  config_path = "${get_repo_root()}/prod/oracle/nsg/allow_https_from_all"
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    id = "fake-id"
  }
}

inputs = {
  dest_cluster_list = [
    {
      cluster = "in-cluster"
      domen = "from-the-lamp.work"
    }
  ]
  project = "infra"
  apps = [
    { 
      helm_chart_name = "gateway"
      helm_repo_url = "https://istio-release.storage.googleapis.com/charts"
      helm_chart_version = local.istio_system_version
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
          oci-network-load-balancer.oraclecloud.com/oci-network-security-groups: "${dependency.allow_https_from_all.outputs.id},${dependency.allow_https_from_all_prod.outputs.id}"
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
