# External HTTPS backend
Creates all required entities to expose an instance set publicly:
- Instance group: each for each region
- External Global IP
- LB: backend service + proxy + url map + forwarding rule + healthcheck
- Domain ssl cert
- Firewall rule

## Params
- external_dns - доменное имя для сертификата (например, newlb.fbs.com)
- network_name - имя VPC (например, common)
- compute_instances - output instances из модуля compute-instance-regional
- compute_instances_target_tags - теги машин из модуля compute-instance-regional, которые нужны для firewall rule

## Usage example
### Example 1
```
module "external_https_backend" {
  source = "git@gitlab.fbs-d.com:terraform/modules/external-https-backend.git"

  external_dns = "newlb.fbs.com"
  network_name = "common"
  compute_instances = module.compute_instance_regional.instances
  compute_instances_target_tags = [ "newlb" ]
}
```

## Outputs
```
- external_https_backend.external_ip
```
