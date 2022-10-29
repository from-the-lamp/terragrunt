[all]
%{ for key, host in ansible_host ~}
${key} ansible_host="${host.address}" ansible_user="${host.user}" k3s_worker_label="${host.label}"
%{ endfor ~}

[all:vars]
k3s_token="${k3s_token}"
ansible_ssh_private_key_file="${ansible_id_rsa}"
lb_ip="${lb_ip}"
