variable "tenancy_ocid" {}
variable "user_ocid" {}
variable "fingerprint" {}
variable "private_key_path" {}
variable "region" {}
variable "compartment_ocid" {}
variable "ssh_public_key" {}
variable "my_public_ip_cidr" {}
variable "cluster_name" {}
variable "environment" {}
variable "os_image_id" {}
variable "availability_domain" {}
variable "vault_url" {}
variable "vault_token" {}
variable "k3s_custom_workers" {
  type = map(object({
    user    = string
    address = string
    label   = string
  }))
}
variable "admin_id_rsa_base64" {
  type      = string
  sensitive = true
}