################################################################################
# Defines the resources to be created
################################################################################

#Order_Service

data "terraform_remote_state" "base_resources" {
  backend = "s3"
  config = {
    bucket  = "lms-playground"
    region  = "us-east-2"
    encrypt = true
    key     = "terraform.tfstate"
  }
}

module "order_service" {
  source                 = "terraform-aws-modules/ecs/aws//modules/service"
  version                = "5.2.2"
  name                   = local.name
  family                 = local.name #unique name for task defination
  cluster_arn            = data.terraform_remote_state.base_resources.outputs.ecs_cluster_arn
  launch_type            = "FARGATE"
  cpu                    = 1024
  memory                 = 2048
  create_iam_role        = true # ECS Service IAM Role: Allows Amazon ECS to make calls to your load balancer on your behalf.
  create_task_definition = true
  create_security_group  = true
  create_tasks_iam_role  = true #ECS Task Role
  desired_count          = 1
  enable_autoscaling     = true
  enable_execute_command = true
  force_new_deployment   = true

  network_mode = "awsvpc"


  # Container definition(s)
  container_definitions = {

    (var.container_name) = {
      cpu       = 512
      memory    = 1024
      essential = true
      image     = var.imageurl
      environment = [
        { "name" : "userServiceURL", "value" : "http://user:3000" },
        { "name" : "productServiceURL", "value" : "http://product:3001" }
      ]
      port_mappings = [
        {
          name          = local.container_name
          containerPort = local.container_port
          hostPort      = local.container_port
          protocol      = "tcp"
        }
      ]
      enable_cloudwatch_logging = true
      memory_reservation        = 100
    }

  }

  subnet_ids = data.terraform_remote_state.base_resources.outputs.private_subnets

  service_connect_configuration = {
    enable    = true
    namespace = data.terraform_remote_state.base_resources.outputs.ecs_service_discovery_arn
    service = {
      client_alias = {
        port     = var.container_port
        dns_name = var.container_name
      }
      port_name      = var.container_name
      discovery_name = var.container_name
    }
  }

  load_balancer = {
    service = {
      target_group_arn = element(data.terraform_remote_state.base_resources.outputs.target_group_arn, 2)
      container_name   = var.container_name
      container_port   = var.container_port
    }
  }


  security_group_rules = {
    alb_ingress_3000 = {
      type                     = "ingress"
      from_port                = var.container_port
      to_port                  = var.container_port
      protocol                 = "tcp"
      description              = "order Service Port"
      source_security_group_id = data.terraform_remote_state.base_resources.outputs.security_group_id
    }

    egress_all = {
      type        = "egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  tags = local.tags
}

resource "aws_iam_role_policy" "task_definition_role-policy" {
  name = "${var.service}-task-definition-role-policy"
  role = module.order_service.tasks_iam_role_name
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "dynamodb:*"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ],
        "Resource" : "*"
      }
    ]
  })
}
