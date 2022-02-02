/*
output "service_domain_names" {
  description = "domain name for each service from the lb"

  # FIXME: return all the domain names for all the services
  value = [module.alb.this_lb_dns_name]
}
*/

output "services" {
  description = "services registered in the this fargate app"

  value = var.services
}

output "execution_role_name" {
  description = "IAM name for the ECS execution task"

  value = aws_iam_role.ecs_execution_role.name
}

output "task_role_name" {
  description = "IAM name for the ECS container task"

  value = aws_iam_role.ecs_task_role.name
}

output "discovery_uri" {
  description = "service discovery URIs for the services"

  value = var.service_discovery == false ? {} : {for key, service in var.services : key => join(".", [key, aws_service_discovery_private_dns_namespace.default[0].name])}
}

output "lb_zone_id" {
  description = "load balancer internal domain hosted zone id"

  value = module.alb.lb_zone_id
}

output "lb_dns_name" {
  description = "load balancer internal domain name"
  value = module.alb.lb_dns_name
}
