locals {
    gitlab_group_id   = "59383214"
    gitlab_group_name = "from-the-lamp"
    cloudflare_record = {
        "dev" = {
            type    = "A",
            proxied = true,
            ttl     = "1"
        },
        "book-dev" = {
            type    = "A",
            proxied = true,
            ttl     = "1"
        },
        "grafana-dev" = {
            type    = "A",
            proxied = true,
            ttl     = "1"
        }
    }
}
