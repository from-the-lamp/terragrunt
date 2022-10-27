[oracle](https://cloud.oracle.com)

k3s_servers_ips = [
  "141.147.63.214",
  "141.147.39.197",
]
k3s_workers_ips = [
  "152.70.180.3",
  "130.61.248.226",
]
public_lb_ip = tolist([
  {
    "ip_address" = "130.61.146.135"
    "ip_version" = "IPV4"
    "is_public" = true
    "reserved_ip" = tolist([])
  },
  {
    "ip_address" = "10.0.1.13"
    "ip_version" = "IPV4"
    "is_public" = false
    "reserved_ip" = tolist([])
  },
])