include "root" {
  path = find_in_parent_folders("root.hcl")
}

# Not Hetzner-specific - just sets cluster_name and generates the talos
# provider - reused as-is.
include "common" {
  path = "${get_repo_root()}/_common/talos/access.hcl"
}

locals {
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  node_1_ip        = local.environment_vars.locals.node_1_ip
}

dependency "secrets" {
  config_path = "${get_repo_root()}/homelab/talos/secrets"
  # "plan" deliberately excluded: talos_client_configuration parses these as
  # real PEM material even during plan, so a mock value would crash instead
  # of a clean "apply talos/secrets first" error.
  mock_outputs_allowed_terraform_commands = ["validate", "output", "init", "destroy"]
  mock_outputs = {
    client_configuration = {
      ca_certificate     = "fake"
      client_certificate = "fake"
      client_key         = "fake"
    }
  }
}

terraform {
  after_hook "write_kubeconfig" {
    commands = ["apply"]
    execute = ["bash", "-c", <<-EOT
      set -euo pipefail
      tf_bin=tofu
      command -v $tf_bin >/dev/null 2>&1 || tf_bin=terraform
      out="${get_terragrunt_dir()}/kubeconfig.yaml"
      $tf_bin output -raw kubeconfig_raw >"$out"
      chmod 600 "$out"
      echo "kubeconfig written to $out"
    EOT
    ]
    run_on_error = false
  }

  after_hook "wait_for_kube_api" {
    commands = ["apply"]
    execute = ["bash", "-c", <<-EOT
      set -euo pipefail
      host="https://${local.node_1_ip}:6443"
      tf_bin=tofu
      command -v $tf_bin >/dev/null 2>&1 || tf_bin=terraform
      ca_file=$(mktemp)
      trap 'rm -f $ca_file' EXIT
      $tf_bin output -raw kubernetes_ca_certificate >$ca_file
      elapsed=0
      while :; do
        if code=$(curl -sS -o /dev/null -w "%%{http_code}" --cacert $ca_file --max-time 5 "$host/readyz" 2>/dev/null); then
          break
        fi
        if [ $elapsed -ge 300 ]; then
          echo "Timed out waiting for $host/readyz (no HTTP response)" >&2
          exit 1
        fi
        sleep 5
        elapsed=$((elapsed + 5))
      done
      echo "kube-apiserver responding at $host (HTTP $code)"
    EOT
    ]
    run_on_error = false
  }
}

inputs = {
  client_configuration = dependency.secrets.outputs.client_configuration
  # Single node - it's simultaneously the only entry in `nodes` and the
  # bootstrap target.
  nodes          = [local.node_1_ip]
  bootstrap_node = local.node_1_ip
  # Hetzner uses the cloud provider's server ID here so a VM replacement
  # (same IP, different underlying server) forces talos_machine_bootstrap/
  # talos_cluster_kubeconfig to re-run. There's no equivalent "replaced but
  # same IP" scenario for a physical box - a literal reinstall is a
  # deliberate, rare, manual event, not something to auto-detect. A
  # constant is enough; bump it by hand if this node is ever wiped and
  # reinstalled from scratch.
  bootstrap_node_id = "homelab-node-1-v1"
}
