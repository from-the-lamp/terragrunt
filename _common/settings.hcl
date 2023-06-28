locals {
  config_file_profile      = get_env("AWS_PROFILE")
  region                   = get_env("DEFAULT_REGION")
  compartment_ocid         = run_cmd("--terragrunt-quiet", "${get_repo_root()}/.kek.sh", "compartment_ocid", "${get_env("OCI_CONFIG_PATH")}", "${get_env("AWS_PROFILE")}")
  availability_domain      = run_cmd("--terragrunt-quiet", "${get_repo_root()}/.kek.sh", "availability_domain", "${get_env("OCI_CONFIG_PATH")}", "${get_env("AWS_PROFILE")}")
  gitlab_token             = get_env("TF_HTTP_PASSWORD")
  private_modules_base_url = "git::https://gitlab-ci-token:${local.gitlab_token}@gitlab.com/from-the-lamp/infra/terraform/modules"
  local_modules_base_path  = "${get_repo_root()}/_modules//"
  infra_project_id         = "40541314"
  k3s_os_image_id          = "ocid1.image.oc1.eu-frankfurt-1.aaaaaaaaj6g2lci5ed7nfhk46olwkhmwkzrobyo3jntnhkk7fnm2vqflorna"
  k3s_admin_ssh_pub        = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICLA+49/73HHo5vMFTeurz8JdDsWza4WvJtN+WnSWi5i \n ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILtNvLcjDTFxc/v03D93cyeEa77jxNC/u2DfqM9gn0k6"
}
