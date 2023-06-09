output "external_ip" {
    value = google_compute_global_address.external_backend_ip.address
}
