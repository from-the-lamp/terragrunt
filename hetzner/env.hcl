locals {
  environment          = "hetzner"
  cluster_name         = "hetzner"
  hetzner_location     = "fsn1"
  hetzner_network_zone = "eu-central"
  private_network_cidr = "10.0.0.0/16"
  private_subnet_cidr  = "10.0.1.0/24"
  # Empty = auto-detect the current public IP of whoever runs terragrunt (see _common/hetzner/firewall.hcl).
  # Set explicitly (e.g. an office/VPN CIDR) to override.
  admin_source_ips   = []
  talos_version      = "v1.9.0"
  kubernetes_version = "1.31.4"
  # System extensions baked into the node image (Image Factory slugs, e.g. "siderolabs/qemu-guest-agent").
  # The schematic ID is registered with Image Factory on every plan/apply (see _common/hetzner/talos_image.hcl) — never hardcode it.
  talos_extensions   = []
  talos_architecture = "x86"

  # Verify current, non-deprecated values with: hcloud server-type list
  node_server_type        = "cpx32"
  image_build_server_type = "cpx22"
}
