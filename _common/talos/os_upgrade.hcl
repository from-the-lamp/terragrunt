terraform {
  source = "${get_repo_root()}/_modules/talos/os_upgrade"
}

locals {
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  talos_version    = local.environment_vars.locals.talos_version
  talos_extensions = local.environment_vars.locals.talos_extensions

  schematic_request_body = jsonencode({
    customization = {
      systemExtensions = {
        officialExtensions = local.talos_extensions
      }
    }
  })

  # Same live-registration approach as _common/hetzner/talos_image.hcl —
  # never hardcode the schematic ID.
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

  installer_image = "factory.talos.dev/installer/${local.talos_schematic_id}:${local.talos_version}"
}

dependency "secrets" {
  config_path = "${get_repo_root()}/hetzner/talos/secrets"
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
  installer_image      = local.installer_image
  client_configuration = dependency.secrets.outputs.client_configuration
}
