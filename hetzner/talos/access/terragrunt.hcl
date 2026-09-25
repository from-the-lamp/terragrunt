include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "common" {
  path = "${get_repo_root()}/_common/talos/access.hcl"
}

dependency "load_balancer" {
  config_path                             = "${get_repo_root()}/hetzner/hetzner/load_balancer"
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    ipv4 = "127.0.0.1"
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
      host="https://${dependency.load_balancer.outputs.ipv4}:6443"
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

dependency "secrets" {
  config_path = "${get_repo_root()}/hetzner/talos/secrets"
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

dependency "node_1" {
  config_path                             = "${get_repo_root()}/hetzner/hetzner/nodes/node-1"
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    id           = "fake-id"
    ipv4_address = "127.0.0.1"
  }
}

dependency "node_2" {
  config_path                             = "${get_repo_root()}/hetzner/hetzner/nodes/node-2"
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    ipv4_address = "127.0.0.2"
  }
}

dependency "node_3" {
  config_path                             = "${get_repo_root()}/hetzner/hetzner/nodes/node-3"
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    ipv4_address = "127.0.0.3"
  }
}

inputs = {
  client_configuration = dependency.secrets.outputs.client_configuration
  nodes = [
    dependency.node_1.outputs.ipv4_address,
    dependency.node_2.outputs.ipv4_address,
    dependency.node_3.outputs.ipv4_address,
  ]
  bootstrap_node    = dependency.node_1.outputs.ipv4_address
  bootstrap_node_id = dependency.node_1.outputs.id
}
