resource "oci_objectstorage_bucket" "test_bucket" {
    compartment_id = var.compartment_ocid
    name = "tg-upload"
    namespace = "results"
}