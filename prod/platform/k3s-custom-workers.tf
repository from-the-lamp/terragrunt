resource "local_file" "ansible_k3s_cunstom_workers_inventory" {
  content = templatefile("ansible/k3s_custom_workers/inventory.tpl",
    {
      ansible_host   = var.k3s_custom_workers
      k3s_token      = module.k3s_cluster.k3s_token
      ansible_id_rsa = "/root/.ssh/id_rsa"
      lb_ip          = module.k3s_cluster.k3s_servers_ips[0]
    }
  )
  filename = "ansible/k3s_custom_workers/inventory"
}

resource "null_resource" "k3s_ansible_playbook" {
  provisioner "local-exec" {
    command = "cd ansible/k3s_custom_workers && ansible-galaxy install -r requirements.yml && ansible-playbook -i inventory playbook.yml"
  }
  depends_on = [local_file.admin_id_rsa]
}
