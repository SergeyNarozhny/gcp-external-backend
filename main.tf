locals {
  dns_flat_list = {
    for dns in var.external_dns_list : dns => {
      dns = dns
      i = index(var.external_dns_list, dns) + 1
    }
  }
}

# Generate random zone for each node
resource "random_string" "random_postfix" {
  length    = var.random_postfix_length
  lower     = true
  upper     = false
  special   = false
}

resource "google_compute_global_address" "external_backend_ip" {
  name = "external-backend-ip-${random_string.random_postfix.result}"
}
resource "google_compute_health_check" "external_backend_healthcheck" {
  name = "external-backend-healthcheck-${random_string.random_postfix.result}"
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
resource "google_compute_instance_group" "external_backend_instance_groups" {
  for_each  = {
    for zone in distinct([ for instance in var.compute_instances: instance.zone ]): zone => [
      for instance in var.compute_instances : instance.id if instance.zone == zone
    ]
  }
  name      = "external-backend-instance-groups-${random_string.random_postfix.result}"
  zone      = each.key
  instances = each.value

  named_port {
    name = var.instance_group_named_protocol
    port = var.instance_group_named_port
  }
}
resource "google_compute_backend_service" "external_backend_service" {
  name = "external-backend-service-${random_string.random_postfix.result}"
  load_balancing_scheme           = "EXTERNAL"
  port_name                       = var.instance_group_named_protocol
  protocol                        = upper(var.instance_group_named_protocol)
  session_affinity                = "NONE"
  connection_draining_timeout_sec = 300
  timeout_sec                     = 30
  health_checks = [ google_compute_health_check.external_backend_healthcheck.self_link ]

  dynamic "backend" {
    for_each = google_compute_instance_group.external_backend_instance_groups
    iterator = instance_group
    content {
      group = instance_group.value.self_link
    }
  }
}
resource "google_compute_url_map" "external_backend_url_map" {
  name = "external-backend-url-map-${random_string.random_postfix.result}"
  default_service = google_compute_backend_service.external_backend_service.id
}
resource "google_compute_target_https_proxy" "external_backend_proxy" {
  name = "external-backend-proxy-${random_string.random_postfix.result}"
  url_map = google_compute_url_map.external_backend_url_map.self_link
  certificate_map = "//certificatemanager.googleapis.com/${google_certificate_manager_certificate_map.external_backend_cert_map.id}"
}
resource "google_compute_global_forwarding_rule" "external_backend_forwarding_rules" {
  load_balancing_scheme = "EXTERNAL"
  name = "external-backend-forwarding-rule-${random_string.random_postfix.result}"
  target     = google_compute_target_https_proxy.external_backend_proxy.id
  ip_address = google_compute_global_address.external_backend_ip.id
  port_range = var.default_https_port
}

# SSL certificate stuff
resource "google_certificate_manager_dns_authorization" "external_backend_dns_auth" {
  for_each    = local.dns_flat_list
  name        = "dns-auth${each.value.i}-${random_string.random_postfix.result}"
  domain      = replace(each.value.dns, "*.", "")
}
resource "google_certificate_manager_certificate" "external_backend_cert" {
  name        = "external-backend-cert-${random_string.random_postfix.result}"
  scope       = "DEFAULT"
  managed {
    domains = concat([
      for domain in google_certificate_manager_dns_authorization.external_backend_dns_auth : domain.domain
    ], [
      for domain in google_certificate_manager_dns_authorization.external_backend_dns_auth : "*.${domain.domain}"
    ])
    dns_authorizations = [ for domain in google_certificate_manager_dns_authorization.external_backend_dns_auth : domain.id ]
  }
}
resource "google_certificate_manager_certificate_map" "external_backend_cert_map" {
  name = "external-backend-cert-map-${random_string.random_postfix.result}"
}
resource "google_certificate_manager_certificate_map_entry" "external_backend_cert_map_entry" {
  for_each     = local.dns_flat_list
  name         = "external-backend-cert-map-entry${each.value.i}-${random_string.random_postfix.result}"
  map          = google_certificate_manager_certificate_map.external_backend_cert_map.name
  certificates = [ google_certificate_manager_certificate.external_backend_cert.id ]
  hostname     = each.value.dns
}
