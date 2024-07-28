include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/oracle/ssh_read_file_content.hcl"
}

dependency "instance_pool" {
  config_path                             = "../instance_pool"
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    instance_ids = ["fake-id"]
  }
}

inputs = {
  display_name = "k3s"
  instance_id  = dependency.instance_pool.outputs.instance_ids[0]
  private_key  = file("~/.ssh/id_rsa")
  use_sudo     = true
  remote_files_paths = [
    "/etc/rancher/k3s/server-ip",
    "/etc/rancher/k3s/server-port",
    "/etc/rancher/k3s/server-certificate-authority-data",
    "/etc/rancher/k3s/client-certificate-data",
    "/etc/rancher/k3s/client-key-data",
    "/etc/rancher/k3s/k3s.yaml"
  ]
}
