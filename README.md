# External HTTPS backend
Creates all required entities to expose an instance set publicly:
- Instance group: each for each region
- External Global IP
- LB: backend service + proxy + url map + forwarding rule + healthcheck
- Domain ssl cert

## Params
- external_dns_list - доменные имена для сертификата (например, ["newlb.fbs.com"]) - все домены пойдут в один сертификат!
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

## Troubleshooting
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
```
