terraform {
  source = "${get_repo_root()}/_modules/hetzner/load_balancer"
}

locals {
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  cluster_name     = local.environment_vars.locals.cluster_name
  hetzner_location = local.environment_vars.locals.hetzner_location
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "hcloud" {
  token = "${get_env("HETZNER_API_TOKEN")}"
}
EOF
}

inputs = {
  name               = "${local.cluster_name}-lb"
  load_balancer_type = "lb11"
  location           = local.hetzner_location
  services = {
    kube_api = {
      protocol         = "tcp"
      listen_port      = 6443
      destination_port = 6443
      health_check = {
        protocol = "tcp"
        port     = 6443
        interval = 10
        timeout  = 5
        retries  = 3
      }
    }
    # destination_port targets the istio-gateway-public NodePort service
    # (apps/platform/istio-system in argo-apps), not port 80/443 on the node
    # directly — this LB is reused for ingress instead of provisioning a
    # second, hcloud-ccm-managed LoadBalancer Service.
    http = {
      protocol         = "tcp"
      listen_port      = 80
      destination_port = 30080
      health_check = {
        protocol = "tcp"
        port     = 30080
        interval = 10
        timeout  = 5
        retries  = 3
      }
    }
    https = {
      protocol         = "tcp"
      listen_port      = 443
      destination_port = 30443
      health_check = {
        protocol = "tcp"
        port     = 30443
        interval = 10
        timeout  = 5
        retries  = 3
      }
    }
  }
}
