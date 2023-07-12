locals {
    gitlab_group_id   = "59383214"
    gitlab_group_name = "from-the-lamp"
    cloudflare_record = {
        "stage" = {
            type    = "A",
            proxied = true,
            ttl     = "1"
        },
        "book-stage" = {
            type    = "A",
            proxied = true,
            ttl     = "1"
        },
        "grafana-stage" = {
            type    = "A",
            proxied = true,
            ttl     = "1"
        }
    }
}
