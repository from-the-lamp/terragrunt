include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/cloudflare/record.hcl"
}

inputs = {
  cloudflare_records = {
    "." = {
      type    = "A",
      proxied = true,
      ttl     = "1"
    },
    "*" = {
      type    = "A",
      proxied = true,
      ttl     = "1"
    }
  }
}
