variable "random_postfix_length" {
  type    = string
  default = 8
}

variable "external_dns_list" {
    type = list(string)
}
variable "external_wildcard_cert_map_id" {
    type = string
    default = ""
}
variable "compute_instances" {
    type = any
    default = []
}

variable "healthcheck_port" {
  type    = string
  default = 443
}
variable "default_https_port" {
  type    = string
  default = 443
}
variable "instance_group_named_protocol" {
  type    = string
  default = "https"
}
variable "instance_group_named_port" {
  type    = string
  default = 443
}
variable "healthcheck_params" {
  type = object({
      check_interval_sec = optional(number)
      healthy_threshold = optional(number)
      unhealthy_threshold = optional(number)
  })
  default = {
      check_interval_sec = 5
      healthy_threshold = 2
      unhealthy_threshold = 2
  }
}
