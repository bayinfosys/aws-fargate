variable "aws_region" { type = string }

variable "project_name"   { type = string }
variable "tags" { type = map(string) }

variable "capacity_providers" { default = ["FARGATE"] }
variable "fargate_cpu" { default = 256 }
variable "fargate_mem" { default = 512 }

variable "vpc_id" { type = string }
variable "vpc_public_subnets" { type = list(string) }
variable "vpc_private_subnets" { type = list(string) }

variable "security_groups" { type = list(string) }

variable "services" {
  type = map(object({

    container_name = string
    container_port = number
    container_definition = object({
      ecr_repository = string
      image_tag = string
      container_cpu = number
      container_mem = number
      container_port = number
      host_port = number
      environment = list(object({
        name = string
        value = string
      }))
    })
  }))
  description = "list of containers, names and ports for the services"
}

variable "target_group_arns" {
  description = "target group arns from the alb module"
  type = list(string)
}
