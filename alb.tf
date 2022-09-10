data "aws_ip_ranges" "region_api_gateway" {
  regions = [var.aws_region]
  services = ["api_gateway"]
}

module "sg" {
  count = length(var.networked_services)

  source  = "terraform-aws-modules/security-group/aws"

  name        = "${var.project_name}-fargate-alb-sg"
  vpc_id      = var.vpc_id

  ingress_cidr_blocks = var.vpc_public_subnets_cidr_blocks
  ingress_rules = ["http-80-tcp"]

  ingress_with_cidr_blocks = [for key, service in var.networked_services :
    {
      from_port   = service.container_definition.host_port
      to_port     = service.container_definition.host_port
      protocol    = "TCP"
      description = key
      cidr_blocks = join(",", var.vpc_public_subnets_cidr_blocks)
    }
    # FIXME: do we need the api gateway cidr blocks?
#    {
#      from_port   = 443
#      to_port     = 443
#      description = "SSL"
#      protocol    = "TCP"
#      cidr_blocks = join(",", data.aws_ip_ranges.region_api_gateway.cidr_blocks)
#    }
  ]

  egress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules = ["all-all"]

  tags = merge(var.tags)
}

module "alb" {
  count = length(var.networked_services)

  source  = "terraform-aws-modules/alb/aws"
  version = "~> 5.10.0"

  name = "${var.project_name}-fargate-alb"

  load_balancer_type = "application"

  vpc_id          = var.vpc_id
  security_groups = [module.sg.security_group_id]
  subnets         = var.vpc_public_subnets

  //  # See notes in README (ref: https://github.com/terraform-providers/terraform-provider-aws/issues/7987)
  //  access_logs = {
  //    bucket = module.log_bucket.this_s3_bucket_id
  //  }

  http_tcp_listeners = [
    {
      port        = 80
      protocol    = "HTTP"
      action_type = "redirect"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  ]

  https_listeners = [
    {
      port               = 443
      protocol           = "HTTPS"
      certificate_arn    = var.acm_certificate_arn
      target_group_index = 0

      action_type = "fixed-response"

      fixed_response = {
        content_type = "text/plain"
        message_body = "lol"
        status_code = "200"
      }
    }
  ]

  # rules per-service
  https_listener_rules = [for key, service in var.networked_services :
    {
      https_listener_index = 0
      priority             = sum([1, index(keys(var.networked_services), key)])

      actions = [
        {
          type               = "forward"
          target_group_index = index(keys(var.networked_services), key)
        }
      ]

      conditions = [{
        # subdomains should be a list with wildcards if needed
        host_headers = [join(".", [service.routing_definition.subdomain, var.project_domain])]
        # headers should be a map {header: [value list]}
        # e.g {content-type = ["json", "xml"]}
        http_headers = [for k, v in service.routing_definition.http_headers : {
          http_header_name = k
          values = v
        }]
      }]
    }
  ]

  # target groups per-service
  target_groups = [ for key, service in var.networked_services :
    {
      name             = "${var.project_name}-${var.env}-${key}"
      backend_protocol = "HTTP"
      backend_port     = service.container_port
      target_type      = "ip"
      port             = service.container_port

      health_check = {
        enabled = true
        interval = 300
        path = service.routing_definition.health_check_path
        port = service.routing_definition.health_check_port
        protocol = "HTTP"
        matcher = "200"
      }

      stickiness = {
        enabled = true
        type = "lb_cookie"
        duration = 86400
      }

      tags = merge(
        var.tags,
        {
           service = key
        }
      )
    }
  ]

  tags = merge(var.tags)
}
