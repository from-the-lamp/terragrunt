locals {
    gitlab_group_id   = "59383214"
    gitlab_group_name = "from-the-lamp"
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
