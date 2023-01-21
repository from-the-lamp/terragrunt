terraform {
  source = "git@gitlab.com:infra154/terraform/modules/k3s-oci-cluster.git//.?ref=main"
}

locals {
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env = local.environment_vars.locals.environment
}

inputs = {
  k3s_load_balancer_name    = "k3s-internal"
  public_load_balancer_name = "k3s-public"
  k3s_server_pool_size      = 2
  k3s_worker_pool_size      = 2
  expose_kubeapi            = true
  my_public_ip_cidr         = "0.0.0.0/0"
  cluster_name              = "infra"
  os_image_id               = "ocid1.image.oc1.eu-frankfurt-1.aaaaaaaaj6g2lci5ed7nfhk46olwkhmwkzrobyo3jntnhkk7fnm2vqflorna"
  availability_domain       = "Wxre:EU-FRANKFURT-1-AD-1"
  region                    = "eu-frankfurt-1"
  admin_ssh_pub             = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICLA+49/73HHo5vMFTeurz8JdDsWza4WvJtN+WnSWi5i \n ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILtNvLcjDTFxc/v03D93cyeEa77jxNC/u2DfqM9gn0k6"
  k3s_load_balancer_name    = "k3s-internal"
  public_load_balancer_name = "k3s-public"
  k3s_server_pool_size      = 2
  k3s_worker_pool_size      = 2
  expose_kubeapi            = true
  my_public_ip_cidr         = "0.0.0.0/0"
  cluster_name              = "infra"
  environment               = "${local.env}"
}
