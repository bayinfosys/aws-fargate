resource "aws_ecs_cluster" "default" {
  name = var.project_name

  capacity_providers = var.capacity_providers

  tags = merge(var.tags)
}

resource "aws_cloudwatch_log_group" "default" {
  name              = var.project_name
  retention_in_days = 5
}
