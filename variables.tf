variable "random_postfix_length" {
  type    = optional(string)
  default = 8
}

variable "external_dns" {
    type = string
}
variable "network_name" {
    type = string
}
variable "compute_instances" {
    type = object(any)
}
variable "compute_instances_target_tags" {
    type = list(string)
}

variable "healthcheck_port" {
  type    = optional(string)
  default = 443
}
variable "instance_group_named_port" {
  type    = optional(string)
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
