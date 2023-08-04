locals {
    gitlab_group_id   = "59383214"
    gitlab_group_name = "from-the-lamp"
    cloudflare_record = {
        "." = {
            type    = "A",
            proxied = true,
            ttl     = "1"
        },
        "book" = {
            type    = "A",
            proxied = true,
            ttl     = "1"
        },
        "grafana" = {
            type    = "A",
            proxied = true,
            ttl     = "1"
        }
    }
}
