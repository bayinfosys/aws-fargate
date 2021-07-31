module "fargate" {
  source = "./modules/fargate"

  aws_region = var.aws_region
  project_name = var.project_name
  tags = merge(var.project_tags, var.network_tags)

  capacity_providers = ["FARGATE"]
  fargate_cpu = 512
  fargate_mem = 2048

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
            name = "LOG_LEVEL"
            value = "DEBUG"
          }
        ]
      }
    }
  }
}
