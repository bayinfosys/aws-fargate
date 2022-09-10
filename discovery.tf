resource "aws_service_discovery_private_dns_namespace" "default" {
  count       = var.service_discovery == false ? 0 : 1
  name        = var.project_name
  description = "${var.project_name} service discovery"
  vpc         = var.vpc_id
}

resource "aws_service_discovery_service" "default" {
  for_each = var.service_discovery == false ? {} : var.networked_services

  name = each.key

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.default[0].id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}
