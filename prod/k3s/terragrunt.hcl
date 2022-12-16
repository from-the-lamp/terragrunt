terraform {
  source = "git@gitlab.com:infra154/terraform/modules/k3s-oci-cluster.git//.?ref=main"
}

include {
  path = find_in_parent_folders()
}

inputs = {
  k3s_load_balancer_name    = "k3s-internal"
  public_load_balancer_name = "k3s-public"
  k3s_server_pool_size      = 2
  k3s_worker_pool_size      = 2
  expose_kubeapi            = true
  my_public_ip_cidr         = "0.0.0.0/0"
  cluster_name              = "infra"
  os_image_id = "ocid1.image.oc1.eu-frankfurt-1.aaaaaaaaj6g2lci5ed7nfhk46olwkhmwkzrobyo3jntnhkk7fnm2vqflorna"
}
