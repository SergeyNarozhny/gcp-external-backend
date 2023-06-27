output "external_ip" {
    value = google_compute_global_address.external_backend_ip.address
}
output "backend_cert" {
    value = google_certificate_manager_certificate.external_backend_cert
}
output "dns_resource_records" {
    value = values(google_certificate_manager_dns_authorization.external_backend_dns_auth)[*].dns_resource_record
}
