variable "aws_region" { type = string }

variable "project_name"   { type = string }
variable "project_domain" { type = string }
variable "env" { type = string }
variable "tags" { type = map(string) }

variable "capacity_providers" { default = ["FARGATE"] }
variable "fargate_cpu" { default = 256 }
variable "fargate_mem" { default = 512 }

variable "vpc_id" { type = string }
variable "vpc_public_subnets" { type = list(string) }
variable "vpc_public_subnets_cidr_blocks" { type = list(string) }
variable "vpc_private_subnets" { type = list(string) }

# NB: terraform gives crap errors if any of these values
#     are missing; it will just say "container_name" required
# FIXME: add a flag for "private-services" which are internal
#        and not on the public subnet
# FIXME: can we use the defaults function here?:
#        https://www.terraform.io/language/functions/defaults
variable "services" {
  type = map(object({

    container_port = string

    routing_definition = object({
      subdomain = string,
      http_headers = map(string),
      health_check_path = string,
      health_check_port = number
    })

    container_definition = object({
      ecr_repository = string
      image_tag = string
      container_cpu = number
      container_mem = number
      host_port = number
      environment = list(object({
        name = string
        value = string
      }))
    })
  }))
  description = "list of containers, names and ports for the services; container_entrypoint and container_command should be []"
}

variable "service_discovery" {
  description = "enable service discovery via private DNS to internal VPC IPs"
  type = bool
  default = false
}

variable "acm_certificate_arn" {
  description = "SSL certificate for ALB endpoints"
  type = string
}
