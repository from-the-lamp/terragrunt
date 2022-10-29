region = "eu-frankfurt-1"
my_public_ip_cidr = "0.0.0.0/0"
cluster_name = "infra"
environment = "prod"
os_image_id = "ocid1.image.oc1.eu-frankfurt-1.aaaaaaaaj6g2lci5ed7nfhk46olwkhmwkzrobyo3jntnhkk7fnm2vqflorna"
availability_domain = "Wxre:EU-FRANKFURT-1-AD-1"
k3s_custom_workers = {
    "eldorado-1" = {
        address = "185.128.106.43"
        user    = "admin"
        label   = "node-group=eldorado"
    }
}
