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

inputs = {
    cloudflare_zone_name = "from-the-lamp.com"
    cloudflare_record = {
        "*" = {
            address = "${dependency.k3s.outputs.public_lb_ip}"
            type    = "A"
            proxied = true
            ttl     = "1"
        }
    }
}
