locals {
  config_file_profile      = get_env("AWS_PROFILE")
  region                   = get_env("DEFAULT_REGION")
  user_ocid                = run_cmd("--terragrunt-quiet", "${get_repo_root()}/.kek.sh", "user", "${get_env("OCI_CONFIG_PATH")}", "${get_env("AWS_PROFILE")}")
  compartment_ocid         = run_cmd("--terragrunt-quiet", "${get_repo_root()}/.kek.sh", "compartment_ocid", "${get_env("OCI_CONFIG_PATH")}", "${get_env("AWS_PROFILE")}")
  availability_domain      = run_cmd("--terragrunt-quiet", "${get_repo_root()}/.kek.sh", "availability_domain", "${get_env("OCI_CONFIG_PATH")}", "${get_env("AWS_PROFILE")}")
  tenancy_ocid             = run_cmd("--terragrunt-quiet", "${get_repo_root()}/.kek.sh", "tenancy", "${get_env("OCI_CONFIG_PATH")}", "${get_env("AWS_PROFILE")}")
  fingerprint              = run_cmd("--terragrunt-quiet", "${get_repo_root()}/.kek.sh", "fingerprint", "${get_env("OCI_CONFIG_PATH")}", "${get_env("AWS_PROFILE")}")
  private_key_path         = run_cmd("--terragrunt-quiet", "${get_repo_root()}/.kek.sh", "key_file", "${get_env("OCI_CONFIG_PATH")}", "${get_env("AWS_PROFILE")}")
  gitlab_token             = get_env("TF_HTTP_PASSWORD")
  private_modules_base_url = "git::https://gitlab-ci-token:${local.gitlab_token}@gitlab.com/from-the-lamp/infra/terraform/modules"
  local_modules_base_path  = "${get_repo_root()}/_modules//"
  infra_project_id         = "40541314"
  admin_ssh_pub            = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILtNvLcjDTFxc/v03D93cyeEa77jxNC/u2DfqM9gn0k6"
  k3s_version              = "v1.25.11+k3s1"
}
