include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "common" {
  path = "${get_repo_root()}/_common/talos/machine_configuration.hcl"
}

dependency "secrets" {
  config_path = "${get_repo_root()}/hetzner/talos/secrets"
  # "plan" deliberately excluded: talos_machine_configuration parses these as
  # real PEM material even during plan, so a mock value would crash instead
  # of a clean "apply talos/secrets first" error.
  mock_outputs_allowed_terraform_commands = ["validate", "output", "init", "destroy"]
  mock_outputs = {
    machine_secrets = {
      certs = {
        etcd = {
          cert = "fake"
          key  = "fake"
        }
        k8s = {
          cert = "fake"
          key  = "fake"
        }
        k8s_aggregator = {
          cert = "fake"
          key  = "fake"
        }
        k8s_serviceaccount = {
          key = "fake"
        }
        os = {
          cert = "fake"
          key  = "fake"
        }
      }
      cluster = {
        id     = "fake"
        secret = "fake"
      }
      secrets = {
        aescbc_encryption_secret    = "fake"
        bootstrap_token             = "fake"
        secretbox_encryption_secret = "fake"
      }
      trustdinfo = {
        token = "fake"
      }
    }
  }
}

dependency "load_balancer" {
  config_path                             = "${get_repo_root()}/hetzner/hetzner/load_balancer"
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    ipv4 = "127.0.0.1"
  }
}

inputs = {
  cluster_endpoint = "https://${dependency.load_balancer.outputs.ipv4}:6443"
  machine_secrets  = dependency.secrets.outputs.machine_secrets
}
