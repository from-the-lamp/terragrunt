terraform {
  source = "${local.modules_url}/${local.module_name}//${local.module_dir}?ref=${local.module_version}"
}

locals {
  common_settings = read_terragrunt_config("${get_repo_root()}/terragrunt.hcl")
  modules_url = local.common_settings.locals.private_modules_base_url
  module_name = "k8s"
  module_dir = "namespaces"
  module_version = "main"
  gitlab_token = local.common_settings.locals.gitlab_token
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env = local.environment_vars.locals.environment
}

dependency "masters" {
  config_path = "${get_repo_root()}/${local.env}/oracle/k3s/masters/ssh_read_file_content"
  mock_outputs_allowed_terraform_commands = ["apply", "plan", "validate", "output", "init", "destroy"]
  skip_outputs = true
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
  helm_module_source = "${local.modules_url}/k8s/helm//?ref=main"
  namespaces = {
    "infra" = {
      labels = [
        {label="istio-injection", value="enabled"},
      ] 
    }
  }
}
