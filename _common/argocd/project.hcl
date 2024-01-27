terraform {
  source = "${local.modules_url}/${local.module_name}//${local.module_dir}?ref=${local.module_version}"
}

locals {
  common_settings = read_terragrunt_config("${get_repo_root()}/terragrunt.hcl")
  modules_url = local.common_settings.locals.private_modules_base_url
  module_name = "argocd"
  module_dir = "project"
  module_version = "main"
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
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
  forward_namespace = "argocd"
  auth_token = get_env("argo_auth_token")
  name = basename(dirname(get_terragrunt_dir()))
  namespace = "argocd"
  source_namespaces = ["infra"]
  source_repos = [
    "!https://gitlab.com/group/from-the-lamp/${basename(dirname(get_terragrunt_dir()))}/**",
     "https://gitlab.com/api/v4/projects/40582099/packages/helm/stable"
  ]
  cluster_resource_whitelist = [
    {
      group = ""
      kind = "Namespace"
    },
    {
      group = "tf.upbound.io"
      kind = "ProviderConfig"
    },
    {
      group = "tf.upbound.io"
      kind = "Workspace"
    }
  ]
  namespace_resource_whitelist = [
    {
      group = "*"
      kind = "*"
    },
    {
      group = "cert-manager.io/v1"
      kind = "Certificate"
    },
  ]
}
