#Cluster-create with capcityprovider

module "secret_manager" {
  source = "../secretmanager_module"
}

module "rds_module" {

source = "../rds_module"
}

module "vpc_create" {
  source = "../vpc_module"
  
}

locals {
  name = "project-wordpress"
}

resource "aws_ecs_cluster" "Project-1" {
  name = local.name
  
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_cluster_capacity_providers" "example" {
  cluster_name = aws_ecs_cluster.Project-1.name

  capacity_providers = ["FARGATE"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}


#ALB

resource "aws_lb" "wordpress_alb" {
  name               = "wordpress-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [module.vpc_create.allow_all_pub]
  subnets            = module.vpc_create.subnets_pub

  enable_deletion_protection = false
}

resource "aws_lb_target_group" "wp_tg" {
  name     = "wordpress-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.vpc_create.vpc_id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.wordpress_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.wp_tg.arn
  }
}


#TaskDefinition

resource "aws_ecs_task_definition" "wordpress" {
  family = "wordpress-td"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  task_role_arn = "arn:aws:iam::992382815594:role/ecsTaskExecutionRole"
  execution_role_arn = "arn:aws:iam::992382815594:role/ecsTaskExecutionRole"
  container_definitions = jsonencode([
    {
      name      = "wordpress"
      image     = "wordpress:latest"
      cpu       = 2
      memory    = 512
      essential = true
      "environment": [
      {"name": "WORDPRESS_DB_HOST", "value": module.rds_module.host_name}, {"name": "WORDPRESS_DB_USER", "valueFrom": module.secret_manager.secret_user_arn}, {"name": "WORDPRESS_DB_PASS", "valueFrom": module.secret_manager.secret_pass_arn}
    ],
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    },
  ])
}

#service

resource "aws_ecs_service" "wordpress" {
  name            = "wordpress-service"
  cluster         = aws_ecs_cluster.Project-1.id
  task_definition = aws_ecs_task_definition.wordpress.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = module.vpc_create.subnets_pvt
    security_groups  = [module.vpc_create.allow_all_pub]
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.wp_tg.arn
    container_name   = "wordpress"
    container_port   = 80
  }

  depends_on = [aws_lb_listener.http]
}