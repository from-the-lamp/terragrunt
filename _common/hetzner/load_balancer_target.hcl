terraform {
  source = "${get_repo_root()}/_modules/hetzner/load_balancer_target"
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "hcloud" {
  token = "${get_env("HETZNER_API_TOKEN")}"
}
EOF
}
