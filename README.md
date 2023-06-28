# External HTTP(S) backend
Creates all required entities to expose an instance set publicly:
- Instance group: each for each region
- External Global IP
- LB: backend service + proxy + url map + forwarding rule + healthcheck
- SSL cert: Certificate manager, DNS authorization requests, certificate map + entries.

## Params
- external_dns_list - доменные имена для сертификата, НЕ для wildcard-сертов, ожидается массив значений в формате ["newlb.cabinettest.com"],
- external_wildcard_cert_map_id - ссылка на id wildcard_cert из модуля tf, в этом случае серты для external_dns_list НЕ ВЫПУСКАЮТСЯ,
- compute_instances - output instances из модуля compute-instance-regional

## Usage example
### Example 1 - https frontend, https backend
```
module "external_https_backend" {
  source = "git@gitlab.fbs-d.com:terraform/modules/external-https-backend.git"

  external_dns_list = ["newlb.cabinettest.com"]
  compute_instances = module.compute_instance_regional.instances

  depends_on = [ module.compute_instance_regional ]
}
```
### Example 2 - https frontend, http backend
```
module "external_https_backend" {
  source = "git@gitlab.fbs-d.com:terraform/modules/external-https-backend.git"

  external_dns_list = ["newlb.cabinettest.com"]
  compute_instances = module.compute_instance_regional.instances
  instance_group_named_protocol = "http"
  instance_group_named_port = "80"
  healthcheck_port = "80"

  depends_on = [ module.compute_instance_regional ]
}
```
### Example 3 - external wildcard cert + https frontend, http backend
```
module "external_https_backend" {
  source = "git@gitlab.fbs-d.com:terraform/modules/external-https-backend.git"

  external_wildcard_cert_map_id = module.wildcard_cert.cert_map_ip
  compute_instances = module.compute_instance_regional.instances
  instance_group_named_protocol = "http"
  instance_group_named_port = "80"
  healthcheck_port = "80"

  depends_on = [ module.compute_instance_regional ]
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
```
