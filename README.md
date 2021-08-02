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
