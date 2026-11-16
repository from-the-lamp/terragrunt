# Not wired through _common/talos/os_upgrade.hcl - that file hardcodes
# dependency "secrets" at hetzner/talos/secrets and the cloud
# `installer` image path. Homelab is bare-metal (`metal-installer` path,
# same convention as homelab/talos/machine_config/node-1) and its
# schematic is static - reuse the already-confirmed-working schematic ID
# directly instead of re-deriving it on every plan/apply. Self-contained,
# same pattern as the other homelab/talos/* units.
include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${local.modules_url}/talos/os_upgrade?tag=1.0.0"
}

locals {
  common_settings  = read_terragrunt_config("${get_repo_root()}/root.hcl")
  modules_url      = local.common_settings.locals.private_modules_base_url
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  talos_version    = local.environment_vars.locals.talos_version
  node_1_ip        = local.environment_vars.locals.node_1_ip
  # Content-addressable hash of the amd-ucode + amdgpu customization -
  # stable across every Talos version. Re-derived (2026-11-16) via a live
  # factory.talos.dev POST when amdgpu was added to env.hcl's
  # talos_extensions, matching homelab/talos/machine_config/node-1's
  # install.image. Re-derive again via the same POST only if
  # talos_extensions ever changes further.
  talos_schematic_id = "9c1d1b442d73f96dcd04e81463eb20000ab014062d22e1b083e1773336bc1dd5"
}

dependency "secrets" {
  config_path = "${get_repo_root()}/homelab/talos/secrets"
  # "plan" deliberately excluded: consumed as real PEM material by a live
  # provisioner; a mock value would crash instead of a clean "not applied
  # yet" error.
  mock_outputs_allowed_terraform_commands = ["validate", "output", "init", "destroy"]
  mock_outputs = {
    client_configuration = {
      ca_certificate     = "fake"
      client_certificate = "fake"
      client_key         = "fake"
    }
  }
}

inputs = {
  node                 = local.node_1_ip
  installer_image      = "factory.talos.dev/metal-installer/${local.talos_schematic_id}:${local.talos_version}"
  client_configuration = dependency.secrets.outputs.client_configuration
  # kexec (the default reboot mode) silently fails to actually reboot into
  # the new image on this box - confirmed twice for v1.14.2 (talosctl
  # reported success, osImage/bootID never changed). powercycle does a
  # real hardware power cycle instead.
  reboot_mode = "powercycle"
}
