locals {
  environment        = "homelab"
  cluster_name       = "homelab"
  talos_version      = "v1.9.0"
  kubernetes_version = "1.31.4"

  # System extensions baked into the installer image (Image Factory slugs).
  # amd-ucode for the UM890 Pro's Ryzen CPU - add a NIC driver extension
  # here too if the box's chipset turns out to need one (check once the
  # hardware is in hand).
  talos_extensions   = ["siderolabs/amd-ucode"]
  talos_architecture = "x86"

  # Pod/service subnets advertised into the same tailnet Hetzner's own
  # subnet router uses (172.20.0.0/16 pods / 172.21.0.0/16 services) - these
  # must NOT overlap. 172.24/172.25 is the next free-looking block but is
  # NOT verified against oracle-prod-0/1 or anything else already
  # advertised - check the Tailscale admin console (Machines -> routes)
  # before first apply.
  pod_subnets     = ["172.24.0.0/16"]
  service_subnets = ["172.25.0.0/16"]

  # Behind a dedicated WISP-mode router (GL.iNet Slate AX or similar), not
  # the shared home LAN - this subnet is fully ours, no collision risk with
  # other devices. 192.168.8.0/24 is GL.iNet's own default LAN range.
  lan_subnet  = "192.168.8.0/24"
  lan_gateway = "192.168.8.1"

  # Per-node static network identity. Add node_2_*/node_3_*/node_4_* the
  # same way when those boxes show up - nothing here assumes exactly one
  # node, it's just that only one exists so far.
  node_1_hostname = "homelab-node-1"
  node_1_ip       = "192.168.8.10"
  # PLACEHOLDER - real interface name is only known after first boot
  # (`talosctl get links`, or the installer shell's `ip link`). Single NIC
  # box, so there's only one candidate, just not named yet.
  node_1_interface = "eth0"
}
