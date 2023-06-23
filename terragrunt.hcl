locals {
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env              = local.environment_vars.locals.environment
  region           = get_env("DEFAULT_REGION")
  s3_namespace     = run_cmd("--terragrunt-quiet", "${get_repo_root()}/.get_s3_namespace.sh", "${get_env("OCI_CONFIG_PATH")}", "${get_env("AWS_PROFILE")}")
}

remote_state {
  backend = "s3"
  generate = {
    path      = "backend.generated.tf"
    if_exists = "overwrite"
  }
  config = {
    bucket                      = "${local.env}-terraform-state"
    key                         = "${path_relative_to_include()}/terraform.tfstate"
    region                      = local.region
    endpoint                    = "https://${local.s3_namespace}.compat.objectstorage.${local.region}.oraclecloud.com"
    shared_credentials_file     = get_env("OCI_CONFIG_PATH")
    skip_region_validation      = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_bucket_root_access     = true
    skip_bucket_enforced_tls    = true
    skip_bucket_versioning      = true
    force_path_style            = true
    disable_bucket_update       = true
  }
}
