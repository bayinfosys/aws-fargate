#
# task definition for each object in the "service" map
#
resource "aws_ecs_task_definition" "default" {
  for_each = var.services

  family = "${var.project_name}-${each.key}"
  requires_compatibilities = ["FARGATE"]
  network_mode = "awsvpc"
  execution_role_arn = aws_iam_role.ecs_execution_role.arn
  task_role_arn = aws_iam_role.ecs_task_role.arn
  cpu = var.fargate_cpu
  memory = var.fargate_mem

  container_definitions = templatefile("${path.module}/task-def.json",
    {
      PROJECT_NAME = var.project_name
      SERVICE_NAME = each.key
      ENV = var.env
      ECR_REPOSITORY = each.value.container_definition.ecr_repository
      IMAGE_TAG = each.value.container_definition.image_tag
      CONTAINER_CPU = each.value.container_definition.container_cpu
      CONTAINER_MEM = each.value.container_definition.container_mem
      ENVIRONMENT = jsonencode(each.value.container_definition.environment)
      HOST_PORT = each.value.container_definition.host_port
      CONTAINER_PORT = each.value.container_definition.container_port
      LOG_REGION = var.aws_region
      LOG_GROUP = "${var.project_name}-${var.env}"
      LOG_PREFIX = each.key
    })

  # https://github.com/cloudposse/terraform-aws-ecs-alb-service-task/issues/39
  tags = merge(var.tags)
}

#
# each object in the "service" map creates a service
#
resource "aws_ecs_service" "default" {
  for_each = var.services

  name            = each.key
  cluster         = aws_ecs_cluster.default.id
  task_definition = aws_ecs_task_definition.default[each.key].arn
  launch_type     = "FARGATE"

  desired_count = 1

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 0

  network_configuration {
    subnets = var.vpc_public_subnets
    security_groups = var.security_groups
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = var.target_group_arns[index(keys(var.services), each.key)]
    container_name = each.value.container_name
    container_port = each.value.container_port
  }

  enable_ecs_managed_tags = true
  propagate_tags = "SERVICE"
  tags = merge(var.tags)
}
