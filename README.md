# AWS Fargate Terraform Module

This module allows the creation of simple `AWS Fargate` deployments to
AWS ECS and have one container per service.


## NOTES

`terraform` will give an error like:

```
The given value is not suitable for child module variable "services" defined
at .terraform/modules/fargate/variables.tf:16,1-20: element
"my-service": attribute "container_name": string required.
```

if one of the required attributes for the `services` variable is missing
from the module definition.


## HTTPS on discovery URI

use the `acm` module to create `SSL` certs for the discovery URIs with:


```terraform
module "acm_fargate_discovery" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 2.0"

  providers = {
    aws = aws.us_east
  }

  domain_name = var.project_domain
  zone_id     = data.aws_route53_zone.primary.zone_id

  subject_alternative_names = concat([ for k, v in module.fargate.discovery_uri: v ])

  wait_for_validation = true
  validation_allow_overwrite_records = true

  tags = merge(var.project_tags)
}
```

This is not included in the module because the `providers` tag may need adjusting
(AWS APIGateway and other resources sometimes require the cert to be issued in
US East region before it can be used).
