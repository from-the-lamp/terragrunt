terraform {
  source = "${get_repo_root()}/_modules/hetzner/talos_image"
}

locals {
  environment_vars        = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  cluster_name            = local.environment_vars.locals.cluster_name
  hetzner_location        = local.environment_vars.locals.hetzner_location
  talos_version           = local.environment_vars.locals.talos_version
  talos_extensions        = local.environment_vars.locals.talos_extensions
  talos_architecture      = local.environment_vars.locals.talos_architecture
  image_build_server_type = local.environment_vars.locals.image_build_server_type
  factory_arch            = local.talos_architecture == "arm" ? "arm64" : "amd64"

  schematic_request_body = jsonencode({
    customization = {
      systemExtensions = {
        officialExtensions = local.talos_extensions
      }
    }
  })

  # Image Factory schematics aren't guaranteed to be stable well-known hashes across
  # Factory deployments/resets — register (idempotent) and read back the real ID instead
  # of hardcoding one.
  talos_schematic_id = run_cmd(
    "--terragrunt-quiet",
    "sh", "-c", <<-EOT
      set -eo pipefail
      id=$(curl -sS -X POST -H "Content-Type: application/json" -d "$1" https://factory.talos.dev/schematics \
        | sed -n 's/.*"id":"\([^"]*\)".*/\1/p')
      if [ -z "$id" ]; then
        echo "talos image factory: empty schematic id" >&2
        exit 1
      fi
      echo "$id"
    EOT
    , "sh", local.schematic_request_body,
  )
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "imager" {
  token = "${get_env("HETZNER_API_TOKEN")}"
}
EOF
}

inputs = {
  image_url    = "https://factory.talos.dev/image/${local.talos_schematic_id}/${local.talos_version}/hcloud-${local.factory_arch}.raw.xz"
  architecture = local.talos_architecture
  location     = local.hetzner_location
  server_type  = local.image_build_server_type
  description  = "talos-${local.talos_version}"
}
