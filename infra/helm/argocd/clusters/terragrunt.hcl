include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/k8s/helm.hcl"
}

dependency "argocd" {
  config_path = "../argocd"
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "output", "init", "destroy"]
  skip_outputs = true
}

dependency "k8s_data_prod_0" {
  config_path = "${get_repo_root()}/prod-0/oracle/k3s/masters/ssh_read_file_content"
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
  helm_chart_name = "argocd-clusters"
  helm_chart_version = "0.0.1"
  helm_values_file = <<-EOF
  clusters:
    prod-0:
      apiUrl: "https://${lookup(dependency.k8s_data_prod_0.outputs.file_contents, "/etc/rancher/k3s/server-ip")}:6443"
      insecure: false
      caData: ${lookup(dependency.k8s_data_prod_0.outputs.file_contents, "/etc/rancher/k3s/server-certificate-authority-data")}
      certData: ${lookup(dependency.k8s_data_prod_0.outputs.file_contents, "/etc/rancher/k3s/client-certificate-data")}
      keyData: ${lookup(dependency.k8s_data_prod_0.outputs.file_contents, "/etc/rancher/k3s/client-key-data")}
  EOF
}
