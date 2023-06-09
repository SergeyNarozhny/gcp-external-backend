# External HTTPS backend
Creates all required entities to expose an instance set publicly:
- Instance group: each for each region
- External Global IP
- LB: backend service + proxy + url map + forwarding rule + healthcheck
- Domain ssl cert

## Params
- external_dns_list - доменные имена для сертификата (например, ["newlb.fbs.com"]) - можно более 15 штук!
- compute_instances - output instances из модуля compute-instance-regionalrule

## Usage example
### Example 1
```
module "external_https_backend" {
  source = "git@gitlab.fbs-d.com:terraform/modules/external-https-backend.git"

  external_dns_list = ["newlb.fbs.com"]
  compute_instances = module.compute_instance_regional.instances
}
```

## Outputs
```
- external_https_backend.external_ip
```
