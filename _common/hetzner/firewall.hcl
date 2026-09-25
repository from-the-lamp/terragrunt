terraform {
  source = "${get_repo_root()}/_modules/hetzner/firewall"
}

locals {
  environment_vars    = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  cluster_name        = local.environment_vars.locals.cluster_name
  private_subnet_cidr = local.environment_vars.locals.private_subnet_cidr
  admin_source_ips    = local.environment_vars.locals.admin_source_ips

  # When env.hcl's admin_source_ips is left empty, fall back to the current
  # public IP of whoever is running terragrunt (mirrors community modules'
  # firewall_use_current_ip convenience). Set admin_source_ips explicitly in
  # env.hcl (office/VPN CIDR) to override.
  #
  # Forced to IPv4 (-4): every talosctl/kube-api call in this repo targets
  # each node's ipv4_address specifically, never its IPv6 address. On a
  # dual-stack client, a protocol-agnostic curl can return an IPv6 address
  # that gets allow-listed here while the actual outbound connection (to an
  # IPv4-only destination) still leaves over IPv4 — silently mismatching
  # the firewall rule and hanging with a connection timeout, not a clean
  # "denied" error.
  current_ip         = run_cmd("--terragrunt-quiet", "sh", "-c", "curl -4 -s -m 5 https://ifconfig.me || true")
  current_ip_is_ipv6 = length(regexall(":", local.current_ip)) > 0
  current_ip_cidr    = local.current_ip != "" ? "${local.current_ip}/${local.current_ip_is_ipv6 ? 128 : 32}" : ""
  effective_admin_source_ips = (
    length(local.admin_source_ips) > 0 ? local.admin_source_ips :
    local.current_ip_cidr != "" ? [local.current_ip_cidr] :
    []
  )
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
  name = "${local.cluster_name}-nodes"
  rules = [
    {
      direction   = "in"
      protocol    = "tcp"
      port        = "6443"
      source_ips  = [local.private_subnet_cidr]
      description = "kube-apiserver (load balancer + node to node)"
    },
    {
      direction   = "in"
      protocol    = "tcp"
      port        = "50000-50001"
      source_ips  = local.effective_admin_source_ips
      description = "talos apid/trustd (terraform + talosctl)"
    },
    {
      direction   = "in"
      protocol    = "tcp"
      port        = "50000-50001"
      source_ips  = [local.private_subnet_cidr]
      description = "talos apid/trustd (node to node)"
    },
    {
      direction   = "in"
      protocol    = "tcp"
      port        = "2379-2380"
      source_ips  = [local.private_subnet_cidr]
      description = "etcd"
    },
    {
      direction   = "in"
      protocol    = "tcp"
      port        = "10250"
      source_ips  = [local.private_subnet_cidr]
      description = "kubelet"
    },
    {
      direction   = "in"
      protocol    = "udp"
      port        = "8472"
      source_ips  = [local.private_subnet_cidr]
      description = "cilium vxlan"
    },
    {
      direction   = "in"
      protocol    = "icmp"
      source_ips  = [local.private_subnet_cidr]
      description = "icmp between nodes"
    },
    # Hetzner Cloud Firewall allows all traffic in a direction with no rules; these make that default explicit rather than silent.
    {
      direction       = "out"
      protocol        = "tcp"
      port            = "1-65535"
      destination_ips = ["0.0.0.0/0", "::/0"]
      description     = "allow all outbound tcp (explicit default, not narrowed)"
    },
    {
      direction       = "out"
      protocol        = "udp"
      port            = "1-65535"
      destination_ips = ["0.0.0.0/0", "::/0"]
      description     = "allow all outbound udp (explicit default, not narrowed)"
    },
    {
      direction       = "out"
      protocol        = "icmp"
      destination_ips = ["0.0.0.0/0", "::/0"]
      description     = "allow all outbound icmp (explicit default, not narrowed)"
    },
  ]
}
