variable "region" {
  type = string
}

variable "compartment_ocid" {
  type      = string
  sensitive = true
}

variable "private_key_path" {
  type      = string
}
