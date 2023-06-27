# External HTTP(S) backend
Creates all required entities to expose an instance set publicly:
- Instance group: each for each region
- External Global IP
- LB: backend service + proxy + url map + forwarding rule + healthcheck
- SSL cert: Certificate manager, DNS authorization requests, certificate map + entries.

## Params
- external_dns_list - доменные имена для сертификата, для wildcard-сертов допустимо одно значение, например, ["*.cabinettest.com"],
- compute_instances - output instances из модуля compute-instance-regionalrule

## Usage example
### Example 1 - https frontend, https backend
```
module "external_https_backend" {
  source = "git@gitlab.fbs-d.com:terraform/modules/external-https-backend.git"

  external_dns_list = ["newlb.fbs.com"]
  compute_instances = module.compute_instance_regional.instances

  depends_on = [ module.compute_instance_regional ]
}
```
### Example 2 - https frontend, http backend
```
module "external_https_backend" {
  source = "git@gitlab.fbs-d.com:terraform/modules/external-https-backend.git"

  external_dns_list = ["newlb.fbs.com"]
  compute_instances = module.compute_instance_regional.instances
  instance_group_named_protocol = "http"
  instance_group_named_port = "80"
  healthcheck_port = "80"

  depends_on = [ module.compute_instance_regional ]
}
```

## DNS
Для корректного выпуска сертификатов по схеме DNS-record авторизации, необходимо создать соответствующие записи (CNAME) на стороне CloudFlare или GCP. Значения записей доступны в output модуля `external_https_backend.dns_resource_records`. Пример для создания записей на CF через terraform:
```
resource "cloudflare_record" "domain_dns_confirmation_records" {
  for_each = {
    for rec in flatten(module.cabinettest_backends.dns_resource_records) : rec.data => rec
  }
  zone_id  = data.cloudflare_zone.cabinettestcom_zone.id
  name     = each.value.name
  value    = each.value.data
  type     = each.value.type
  proxied  = false
}
```

## Troubleshooting
### for_each map ... cannot be determined
In case of issues like:
```
│ The "for_each" map includes keys derived from resource attributes that cannot be determined until apply, and so Terraform cannot
│ determine the full set of keys that will identify the instances of this resource.
│
│ When working with unknown values in for_each, it's better to define the map keys statically in your configuration and place apply-time
│ results only in the map values.
```
Use `terraform apply -target module.compute_instance_regional` to create dependant instances first.

## Outputs
```
- external_https_backend.external_ip
- external_https_backend.backend_cert
- external_https_backend.dns_resource_records
```
