/*
==============================================================================
App Module: Application Infrastructure
==============================================================================
Provisions application tier components:
- Application Load Balancer (ALB) with HTTPS
- ECS Fargate cluster and service
- ECR repositories for container images
- IAM roles for ECS task execution
- S3 bucket for static frontend hosting
==============================================================================
*/

# Application Load Balancer
resource "aws_lb" "this" {
  name               = "${var.project}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.public_subnet_ids

  tags = {
    Name = "${var.project}-alb"
  }
}

# ALB HTTP Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# ALB HTTPS Listener
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.this.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# Target Group
resource "aws_lb_target_group" "app" {
  name        = "${var.project}-tg"
  port        = 5000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = "/health"
    port                = "5000"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
    matcher             = "200-399"
  }

  tags = {
    Name = "${var.project}-tg"
  }
}

# ECR Repository (API)
resource "aws_ecr_repository" "ecr_api_repo" {
  name         = "${var.project}-api-repo"
  force_delete = true

  tags = {
    Name = "${var.project}-api-repo"
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "this" {
  name = "${var.project}-ecs-cluster"

  tags = {
    Name = "${var.project}-ecs-cluster"
  }
}

# ECS Execution Role for App
resource "aws_iam_role" "ecs_exec_app" {
  name = "${var.project}-ecs-exec-app-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ecs-tasks.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })


  tags = {
    Name = "${var.project}-ecs-exec-app-role"
  }
}

data "aws_iam_policy_document" "app_exec_secrets" {
  statement {
    sid    = "ReadSecretsForInjection"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]
    resources = [
      var.db_app_credentials_arn
    ]
  }
}

# IAM Policy to allow ECS Task to read DB credentials from Secrets Manager
resource "aws_iam_policy" "app_secrets_policy" {
  name        = "${var.project}-app-secrets-policy"
  description = "Policy to allow ECS task to read DB credentials from Secrets Manager"
  policy      = data.aws_iam_policy_document.app_exec_secrets.json
}

# Policy Attachment for ECS App Execution Role
resource "aws_iam_role_policy_attachment" "ecs_exec_app_policy_attach" {
  role       = aws_iam_role.ecs_exec_app.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Policy Attachment for App Secrets Access
resource "aws_iam_role_policy_attachment" "app_secrets_policy_attach" {
  role       = aws_iam_role.ecs_exec_app.name
  policy_arn = aws_iam_policy.app_secrets_policy.arn
}

# ECS Task Definition (API)
resource "aws_ecs_task_definition" "api" {
  family                   = "${var.project}-api-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_exec_app.arn
  container_definitions = jsonencode([
    {
      name  = "api-container"
      image = "${aws_ecr_repository.ecr_api_repo.repository_url}:${var.api_image_tag}"
      portMappings = [
        {
          containerPort = 5000
          hostPort      = 5000
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "DB_HOST"
          value = var.db_host
        },
        {
          name  = "DB_NAME"
          value = var.db_name
        },
        {
          name  = "DB_PORT"
          value = tostring(var.db_port)
        }
      ]

      secrets = [
        {
          name      = "DB_USERNAME"
          valueFrom = "${var.db_app_credentials_arn}:username::"
        },
        {
          name      = "DB_PASSWORD"
          valueFrom = "${var.db_app_credentials_arn}:password::"
        }
      ]
    }
  ])
}

# ECS Service (API)
resource "aws_ecs_service" "api" {
  name                               = "${var.project}-api-service"
  cluster                            = aws_ecs_cluster.this.id
  task_definition                    = aws_ecs_task_definition.api.arn
  desired_count                      = var.api_desired_count
  deployment_minimum_healthy_percent = 0 # Allow zero-downtime deployments
  launch_type                        = "FARGATE"

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "api-container"
    container_port   = 5000
  }

  lifecycle {
    ignore_changes = [desired_count]
  }

  network_configuration {
    subnets          = var.private_app_subnet_ids
    security_groups  = [var.ecs_tasks_sg_id]
    assign_public_ip = false
  }

  depends_on = [aws_lb_listener.https]

  tags = {
    Name = "${var.project}-api-service"
  }
}

