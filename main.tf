locals {
  # https://confluence.ddl.com/pages/viewpage.action?pageId=31066628 - see the right column
  vpn_office_list = [
    "10.0.0.0/8",
    "89.104.126.0/24",
    "23.109.89.0/24",
    "89.19.36.96/27",
    "154.61.138.0/24",
    "91.148.119.22/32",
    "45.147.161.80/28",
    "108.137.130.92/32"
  ]
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
  security_policy = var.allow_under_VPN_only ? google_compute_security_policy.external_backend_security_policy[0].self_link : null

  log_config {
    enable = true
  }

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
resource "google_compute_managed_ssl_certificate" "external_backend_cert" {
  count = var.external_wildcard_cert_map_id == "" ? 1 : 0
  name  = "external-backend-cert-${random_string.random_postfix.result}"
  managed {
    domains = toset(var.external_dns_list)
  }
}
resource "google_compute_target_https_proxy" "external_backend_proxy" {
  name = "external-backend-proxy-${random_string.random_postfix.result}"
  url_map = google_compute_url_map.external_backend_url_map.self_link
  certificate_map = var.external_wildcard_cert_map_id != "" ? "//certificatemanager.googleapis.com/${var.external_wildcard_cert_map_id}" : null
  ssl_certificates = var.external_wildcard_cert_map_id == "" ? [ google_compute_managed_ssl_certificate.external_backend_cert[0].id ] : null
}
resource "google_compute_global_forwarding_rule" "external_backend_forwarding_rules" {
  load_balancing_scheme = "EXTERNAL"
  name = "external-backend-forwarding-rule-${random_string.random_postfix.result}"
  target     = google_compute_target_https_proxy.external_backend_proxy.id
  ip_address = google_compute_global_address.external_backend_ip.id
  port_range = var.default_https_port
}
# Cloud Armor firewall if needed
resource "google_compute_security_policy" "external_backend_security_policy" {
  count = var.allow_under_VPN_only ? 1 : 0
  name = "external-backend-security-policy-${random_string.random_postfix.result}"

  rule {
    action   = "allow"
    priority = "1001"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = local.vpn_office_list
      }
    }
    description = "Allow access under VPN"
  }

  rule {
    action   = "deny(403)"
    priority = "2147483647"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    description = "Deny everything else"
  }
}
