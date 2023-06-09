locals {
  https_port = "443"
  zone_to_vms_map = {
    for zone in distinct([ for instance in local.compute_instances: instance.zone ]): zone => [
      for instance in local.compute_instances : instance.id if instance.zone == zone
    ]
  }
}

# Generate random zone for each node
resource "random_string" "random_postfix" {
  length    = var.random_postfix_length
  lower     = true
  upper     = false
  special   = false
}

resource "google_compute_global_address" "external_https_backend_ip" {
  name = "external-https-backend-ip-${random_string.random_postfix.result}"
}
resource "google_compute_health_check" "external_https_backend_healthcheck"{
  name = "external-https-backend-healthcheck-${random_string.random_postfix.result}"
  check_interval_sec  = var.healthcheck_params.check_interval_sec
  healthy_threshold   = var.healthcheck_params.healthy_threshold
  unhealthy_threshold = var.healthcheck_params.unhealthy_threshold

  log_config {
    enable = true
  }
  tcp_health_check {
    port = var.healthcheck_port
  }
}
resource "google_compute_instance_group" "external_https_backend_instance_groups" {
  for_each  = local.zone_to_vms_map
  name      = "external-https-backend-instance-groups-${random_string.random_postfix.result}"
  zone      = each.key
  instances = each.value

  named_port {
    name = "https"
    port = var.instance_group_named_port
  }
}
resource "google_compute_backend_service" "external_https_backend_service" {
  name = "external-https-backend-service-${random_string.random_postfix.result}"
  load_balancing_scheme           = "EXTERNAL"
  port_name                       = "https"
  protocol                        = "HTTPS"
  session_affinity                = "NONE"
  connection_draining_timeout_sec = 300
  timeout_sec                     = 30
  health_checks = [ google_compute_health_check.external_https_backend_healthcheck.self_link ]

  dynamic "backend" {
    for_each = google_compute_instance_group.external_https_backend_instance_groups
    iterator = instance_group
    content {
      group = instance_group.value.self_link
    }
  }
}
resource "google_compute_url_map" "external_https_backend_url_map" {
  name = "external-https-backend-url-map-${random_string.random_postfix.result}"
  default_service = google_compute_backend_service.external_https_backend_service.id
}
resource "google_compute_managed_ssl_certificate" "external_https_backend_cert" {
  name = "external-https-backend-cert-${random_string.random_postfix.result}"
  managed {
    domains = [ var.external_dns ]
  }
}
resource "google_compute_target_https_proxy" "external_https_backend_https_proxy" {
  name = "external-https-backend-https-proxy-${random_string.random_postfix.result}"
  url_map = google_compute_url_map.external_https_backend_url_map.self_link
  ssl_certificates = [ google_compute_managed_ssl_certificate.external_https_backend_cert.id ]
}
resource "google_compute_global_forwarding_rule" "external_https_backend_forwarding_rule" {
  name = "external-https-backend-forwarding-rule-${random_string.random_postfix.result}"
  load_balancing_scheme = "EXTERNAL"
  target     = google_compute_target_https_proxy.external_https_backend_https_proxy.id
  ip_address = google_compute_global_address.external_https_backend_ip.id
  port_range = local.https_port
}
resource "google_compute_firewall" "external_https_backend_firewall" {
    name = "external-https-backend-firewall-${random_string.random_postfix.result}"
    network = var.network_name
    allow {
        protocol = "tcp"
        ports    = [ local.https_port ]
    }
    source_ranges = [
        "0.0.0.0/0"
    ]
    target_tags = var.compute_instances_target_tags
}
