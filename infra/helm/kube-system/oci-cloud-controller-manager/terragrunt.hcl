include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/k8s/helm.hcl"
}

locals {
  environment_vars             = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env                          = local.environment_vars.locals.environment
  common_settings              = read_terragrunt_config("${get_repo_root()}/terragrunt.hcl")
  compartment_ocid             = local.common_settings.locals.compartment_ocid
  helm_repo_url                = local.common_settings.locals.infra_helm_repo_url
  helm_repo_user               = local.common_settings.locals.helm_repo_user
  helm_repo_pass               = local.common_settings.locals.helm_repo_pass
  versions                     = read_terragrunt_config("${get_repo_root()}/_common/versions.hcl")
  oci_cloud_controller_manager = local.versions.locals.oci_cloud_controller_manager
}

dependency "vcn" {
  config_path = "${get_repo_root()}/${local.env}/oracle/vcn"
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    vcn_id = "fake-id"
    subnets_ids = {"k3s" = "fake-data"}
  }
}

dependency "master" {
  config_path = "${get_repo_root()}/${local.env}/oracle/k3s/masters/ssh_read_file_content"
  mock_outputs_allowed_terraform_commands = ["apply" ,"plan", "validate", "output", "init", "destroy"]
  skip_outputs = true
}

inputs = {
  helm_repo_url      = local.helm_repo_url
  helm_repo_user     = local.helm_repo_user
  helm_repo_pass     = local.helm_repo_pass
  helm_chart_version = local.oci_cloud_controller_manager
  k8s_namespace      = "kube-system"
  helm_values_file = <<-EOF
  compartment: ${local.compartment_ocid}
  vcn: ${dependency.vcn.outputs.vcn_id}
  loadBalancer:
    subnet1: ${lookup(dependency.vcn.outputs.subnets_ids, "k3s")}
  external: true
  EOF
}
