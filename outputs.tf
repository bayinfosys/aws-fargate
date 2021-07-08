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
