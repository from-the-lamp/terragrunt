include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/k8s/helm.hcl"
}

locals {
  environment_vars             = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env                          = local.environment_vars.locals.environment
  common_settings              = read_terragrunt_config("${get_repo_root()}/_common/settings.hcl")
  compartment_ocid             = local.common_settings.locals.compartment_ocid
  region                       = local.common_settings.locals.region
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
  helm_internal_repo = true
  helm_chart_name    = "oci-cloud-controller-manager"
  helm_chart_version = local.oci_cloud_controller_manager
  k8s_namespace      = "kube-system"
  helm_addition_setting = {
    compartment            = local.compartment_ocid
    vcn                    = dependency.vcn.outputs.vcn_id
    "loadBalancer.subnet1" = lookup(dependency.vcn.outputs.subnets_ids, "k3s")
  }
}
