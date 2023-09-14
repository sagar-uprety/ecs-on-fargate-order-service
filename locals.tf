locals {
  name           = "order_service"
  project        = "ecs-module-lms"
  container_name = "order"
  container_port = 3002
  tags = {
    Name    = local.name,
    Project = local.project
  }
}
