terraform {
  source = "git@gitlab.com:infra154/terraform/modules/cloudflare-dns-record.git//.?ref=main"
}

locals {
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env = local.environment_vars.locals.environment
}

dependency "k3s" {
  config_path = "../k3s"
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "output", "init"]
  mock_outputs = {
    public_lb_ip = "1.2.3.4"
  }
}

dependency "get_infra_variables" {
  config_path = "../gitlab/get_infra_variables"
  mock_outputs_allowed_terraform_commands = ["apply" ,"plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    "map_variables.cloudflare_api_token" = "fake-token"
  }
}

inputs = {
    cloudflare_api_token = dependency.get_infra_variables.outputs.map_variables.cloudflare_api_token
    cloudflare_zone_name = "from-the-lamp.com"
    cloudflare_record = {
        "." = {
            address = "${dependency.k3s.outputs.public_lb_ip}"
            type    = "A"
            proxied = true
            ttl     = "1"
        }
        "*" = {
            address = "${dependency.k3s.outputs.public_lb_ip}"
            type    = "A"
            proxied = true
            ttl     = "1"
        }
    }
}
