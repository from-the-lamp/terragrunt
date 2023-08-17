include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/gitlab/add_variables.hcl"
}

locals {
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env              = local.environment_vars.locals.environment
}

dependency "ssh_read_file_content" {
  config_path = "${get_repo_root()}/${local.env}/oracle/k3s/masters/ssh_read_file_content"
  mock_outputs_allowed_terraform_commands = ["apply", "plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    file_contents = {"/etc/rancher/k3s/k3s.yaml" = "fake-data"}
  }
}

dependency "cloudflare_api_token" {
  config_path = "../cloudflare_api_token"
  mock_outputs_allowed_terraform_commands = ["apply" ,"plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    "cloudflare_api_token" = "fake-token"
  }
}

dependency "dns" {
  config_path = "../dns"
  mock_outputs_allowed_terraform_commands = ["apply" ,"plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    "cloudflare_zone_id" = "fake-id"
  }
}

dependency "argocd_pass" {
  config_path = "${get_repo_root()}/${local.env}/oracle/k3s/workers/argocd/argocd_pass"
  mock_outputs_allowed_terraform_commands = ["apply" ,"plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    "password" = "fake-pass"
  }
}

inputs = {
  vars = {
    "CLOUDFLARE_ZONE_ID" = {
      value     = "${dependency.dns.outputs.cloudflare_zone_id}"
      protected = false
      masked    = true
    },
    "CLOUDFLARE_API_TOKEN" = {
      value     = "${dependency.cloudflare_api_token.outputs.cloudflare_api_token}"
      protected = false
      masked    = true
    },
    "ARGOCD_PASSWORD" = {
      value     = "${dependency.argocd_pass.outputs.password}"
      protected = false
      masked    = true
    },
  }
}
