include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "common" {
  path = "${get_repo_root()}/_common/oracle/kms_vault_secrets.hcl"
}

dependency "vault_infra" {
  config_path                             = "${get_repo_root()}/infra/oracle/vaults/infra"
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    vault_id = "fake-vault-id"
    key_id   = "fake-key-id"
  }
}

dependency "oauth_client" {
  config_path                             = "../client"
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    client_id     = "fake-client-id"
    client_secret = "fake-client-secret"
  }
}

dependency "oauth_exit_client" {
  config_path                             = "../exit-client"
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    client_id     = "fake-exit-client-id"
    client_secret = "fake-exit-client-secret"
  }
}

inputs = {
  vault_id = dependency.vault_infra.outputs.vault_id
  key_id   = dependency.vault_infra.outputs.key_id
  secrets = {
    tailscale = jsonencode({
      oauth_client_id     = dependency.oauth_client.outputs.client_id
      oauth_client_secret = dependency.oauth_client.outputs.client_secret
    })
    # Separate credential for the exit-node hostNode (see
    # ../exit-client) - it needs tag:exit alone, which can't share a
    # client with the operator's own tag (see that unit's comment).
    tailscale-exit = jsonencode({
      oauth_client_id     = dependency.oauth_exit_client.outputs.client_id
      oauth_client_secret = dependency.oauth_exit_client.outputs.client_secret
    })
  }
}
