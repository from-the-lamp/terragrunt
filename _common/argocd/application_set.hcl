terraform {
  source = "${local.modules_url}/${local.module_name}//${local.module_dir}?ref=${local.module_version}"
}

locals {
  common_settings = read_terragrunt_config("${get_repo_root()}/terragrunt.hcl")
  modules_url = local.common_settings.locals.private_modules_base_url
  module_name = "argocd"
  module_dir = "application_set"
  module_version = "main"
  infra_helm_repo_url = local.common_settings.locals.infra_helm_repo_url
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  dns_zone_name = local.environment_vars.locals.dns_zone_name
  env = local.environment_vars.locals.environment
}

dependency "ssh_read_file_content" {
  config_path = "${get_repo_root()}/${local.env}/oracle/k3s/masters/ssh_read_file_content"
  mock_outputs_allowed_terraform_commands = ["apply", "plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    file_contents = {
      "/etc/rancher/k3s/server-ip" = "ZmFrZS1kYXRhCg==",
      "/etc/rancher/k3s/server-certificate-authority-data" = "ZmFrZS1kYXRhCg==",
      "/etc/rancher/k3s/client-certificate-data" = "ZmFrZS1kYXRhCg==",
      "/etc/rancher/k3s/client-key-data" = "ZmFrZS1kYXRhCg==",
    }
  }
}

inputs = {
  host = "https://${lookup(dependency.ssh_read_file_content.outputs.file_contents, "/etc/rancher/k3s/server-ip")}:6443"
  cluster_ca_certificate = <<-EOF
${base64decode(lookup(dependency.ssh_read_file_content.outputs.file_contents, "/etc/rancher/k3s/server-certificate-authority-data"))}
    EOF
  client_certificate = <<-EOF
${base64decode(lookup(dependency.ssh_read_file_content.outputs.file_contents, "/etc/rancher/k3s/client-certificate-data"))}
    EOF
  client_key = <<-EOF
${base64decode(lookup(dependency.ssh_read_file_content.outputs.file_contents, "/etc/rancher/k3s/client-key-data"))}
    EOF
  forward_namespace = "infra"
  auth_token = get_env("argo_auth_token")
  app_name = "${basename(dirname(get_terragrunt_dir()))}-${basename(get_terragrunt_dir())}"
  release_name = basename(get_terragrunt_dir())
  app_namespace = "infra"
  dest_namespace = basename(dirname(get_terragrunt_dir()))
  helm_repo_url = local.infra_helm_repo_url
  helm_chart_name = basename(get_terragrunt_dir())
  project = basename(dirname(get_terragrunt_dir()))
  sync_options = ["CreateNamespace=true"]
  namespace_labels = {
    "istio-injection" = "enabled"
  }
  dest_cluster_list = [
    {
      cluster = "in-cluster"
      domen = "from-the-lamp.work"
    },
    {
      cluster = "prod-0"
      domen = "from-the-lamp.com"
    }
  ]
  ignore_difference = [
    {
      group = "cert-manager.io"
      kind = "Certificate"
      json_pointers = [
        "/spec/duration",
        "/spec/renewBefore"
      ]
      jq_path_expressions = []
    },
    {
      name = "istiod-default-validator"
      group = "admissionregistration.k8s.io"
      kind = "ValidatingWebhookConfiguration"
      jq_path_expressions = [
        ".webhooks[].failurePolicy"
      ]
    }    
  ]
}
