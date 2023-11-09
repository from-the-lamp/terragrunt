locals {
    gitlab_group_full_path = "from-the-lamp"
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
