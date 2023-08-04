terraform {
  source = "${local.private_modules_base_url}/${local.module_name}//${local.module_subdir}?ref=${local.module_version}"
}

locals {
  module_name              = "cloudflare"
  module_subdir            = "dns_record"
  module_version           = "main"
  private_modules_base_url = local.common_settings.locals.private_modules_base_url
  common_settings          = read_terragrunt_config("${get_repo_root()}/_common/settings.hcl")
  environment_vars         = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env                      = local.environment_vars.locals.environment
  infra_zone               = local.environment_vars.locals.infra_zone
}

dependency "get_infra_variables" {
  config_path = "${get_repo_root()}/${local.env}/gitlab/get_infra_variables"
  mock_outputs_allowed_terraform_commands = ["apply" ,"plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    map_variables = {
      cloudflare_api_token = "fake-token"
    }
  }
}

dependency "ssh_read_file_content" {
  config_path = "${get_repo_root()}/${local.env}/oracle/k3s/masters/ssh_read_file_content"
  mock_outputs_allowed_terraform_commands = ["apply", "plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    file_contents = {
      "/etc/rancher/k3s/server" = "ZmFrZS1kYXRhCg==",
      "/etc/rancher/k3s/certificate-authority-data" = "ZmFrZS1kYXRhCg==",
      "/etc/rancher/k3s/client-certificate-data" = "ZmFrZS1kYXRhCg==",
      "/etc/rancher/k3s/client-key-data" = "ZmFrZS1kYXRhCg==",
    }
  }
}

dependency "lb" {
  config_path = "${get_repo_root()}/${local.env}/helm/gateway/istio-ingressgateway"
  mock_outputs_allowed_terraform_commands = ["apply" ,"plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    skip_outputs = true
  }
}

generate "provider_kubernetes" {
  path      = "kubernetes.generated.tf"
  if_exists = "overwrite"
  contents = <<EOF1
provider "kubernetes" {
    host = "https://${lookup(dependency.ssh_read_file_content.outputs.file_contents, "/etc/rancher/k3s/server")}:6443"
    cluster_ca_certificate = <<-EOF2
${base64decode(lookup(dependency.ssh_read_file_content.outputs.file_contents, "/etc/rancher/k3s/certificate-authority-data"))}
    EOF2
    client_certificate = <<-EOF2
${base64decode(lookup(dependency.ssh_read_file_content.outputs.file_contents, "/etc/rancher/k3s/client-certificate-data"))}
    EOF2
    client_key= <<-EOF2
${base64decode(lookup(dependency.ssh_read_file_content.outputs.file_contents, "/etc/rancher/k3s/client-key-data"))}
    EOF2
}
EOF1
}

inputs = {
  cloudflare_api_token      = dependency.get_infra_variables.outputs.map_variables.cloudflare_api_token
  cloudflare_zone_name      = local.infra_zone
  external_load_balancer    = true
  external_lb_svc_name      = "istio-ingressgateway"
  external_lb_svc_namespace = "gateway"
  internal_load_balancer    = false
}
