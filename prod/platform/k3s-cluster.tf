module "k3s_cluster" {
  region                    = var.region
  availability_domain       = var.availability_domain
  tenancy_ocid              = var.tenancy_ocid
  compartment_ocid          = var.compartment_ocid
  my_public_ip_cidr         = var.my_public_ip_cidr
  cluster_name              = var.cluster_name
  environment               = var.environment
  os_image_id               = var.os_image_id
  source                    = "github.com/garutilorenzo/k3s-oci-cluster"
  k3s_load_balancer_name    = "k3s-internal"
  public_load_balancer_name = "k3s-public"
  install_nginx_ingress     = true
  expose_kubeapi            = true
}

output "k3s_servers_ips" {
  value = module.k3s_cluster.k3s_servers_ips
}

output "k3s_workers_ips" {
  value = module.k3s_cluster.k3s_workers_ips
}

output "public_lb_ip" {
  value = module.k3s_cluster.public_lb_ip
}
