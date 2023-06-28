output "external_ip" {
    value = google_compute_global_address.external_backend_ip.address
}
output "backend_cert" {
    value = google_compute_managed_ssl_certificate.external_backend_cert
}
