module "fargate" {
  source = "./modules/fargate"

  aws_region = var.aws_region
  project_name = var.project_name
  tags = merge(var.project_tags, var.network_tags)

  fargate_cpu = 512
  fargate_mem = 2048
  capacity_providers = ["FARGATE_SPOT"]

  vpc_id = module.vpc.vpc_id
  vpc_public_subnets = module.vpc.public_subnets
  vpc_private_subnets = module.vpc.private_subnets

  target_group_arns = module.alb.target_group_arns
  security_groups = [module.alb_sg.this_security_group_id]

  services = {
    service_a = {
      container_name = "${var.project_name}-service_a"
      container_port = 5000

      container_definition = {
        ecr_repository = data.aws_ecr_repository.backend.repository_url
        image_tag = data.aws_ecr_image.processing.image_tag
        container_cpu = 256
        container_mem = 1024
        container_port = 5000
        host_port = 5000
        environment = [
          {
            name = "DB_CONN_STR"
            value = "http://dynamodb.eu-west-2.amazonaws.com"
          },
          {
            name = "LOG_LEVEL"
            value = "DEBUG"
          }
        ]
      }
    }

    service_b = {
      container_name = "${var.project_name}-service_b"
      container_port = 5000

      container_definition = {
        ecr_repository = data.aws_ecr_repository.backend.repository_url
        image_tag = data.aws_ecr_image.dbview.image_tag
        container_cpu = 256
        container_mem = 512
        container_port = 5000
        host_port = 5000
        environment = [
          {
            name = "DB_CONN_STR"
            value = "http://dynamodb.eu-west-2.amazonaws.com"
          }
        ]
      }
    }
  }
}

#
# add dynamodb to the fargate execution task
#
resource "aws_iam_role_policy_attachment" "ecs_task_role" {
  role = module.fargate.task_role_name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}
