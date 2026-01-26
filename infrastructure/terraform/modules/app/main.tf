# Application Load Balancer
resource "aws_lb" "this" {
  name               = "${var.project}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
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
      type  = "redirect"
      redirect {
        port          = "443"
        protocol      = "HTTPS"
        status_code   = "HTTP_301"
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
  target_type = "instance"

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

# Launch Template
resource "aws_launch_template" "this" {
  name_prefix   = "${var.project}-lt-"
  image_id      = data.aws_ami.amazon_linux_2.id
  instance_type = "t3.micro"
  vpc_security_group_ids = [aws_security_group.ec2.id]

  iam_instance_profile {
    name = aws_iam_instance_profile.ssm_profile.name
  }

  user_data = base64encode(file("${path.root}/../scripts/user_data.sh"))

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "${var.project}-app"
    }
  }
}

# Auto Scaling Group (how many, where, and scaling)
resource "aws_autoscaling_group" "app" {
  name                 = "${var.project}-asg"
  vpc_zone_identifier  = var.private_subnet_ids
  desired_capacity     = 2
  min_size             = 1
  max_size             = 4
  health_check_type    = "EC2"
  target_group_arns    = [aws_lb_target_group.app.arn]

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project}-asg"
    propagate_at_launch = true
  }
}

# IAM Role for SSM
resource "aws_iam_role" "ssm_role" {
  name = "${var.project}-ec2-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Attach the AmazonSSMManagedInstanceCore policy
resource "aws_iam_role_policy_attachment" "ssm_attach" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# IAM Instance Profile for EC2
resource "aws_iam_instance_profile" "ssm_profile" {
  name = "${var.project}-ec2-ssm-profile"
  role = aws_iam_role.ssm_role.name
}

# Secrets Manager Access Policy (to allow EC2 to read DB credentials)
resource "aws_iam_role_policy" "secrets_access" {
  name = "${var.project}-secrets-access"
  role = aws_iam_role.ssm_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["secretsmanager:GetSecretValue"],
        Resource = data.aws_secretsmanager_secret.db.arn
      }
    ]
  })
}

# S3 Bucket for Frontend Hosting
resource "aws_s3_bucket" "frontend" {
  bucket        = "${var.project}-frontend"
  force_destroy = false

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name = "${var.project}-frontend"
  }
}

# Configure the website hosting (index and error docs)
resource "aws_s3_bucket_website_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

# Disable Block Public Access settings
resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket                  = aws_s3_bucket.frontend.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Allow public reads for the website
resource "aws_s3_bucket_policy" "frontend_public" {
  bucket = aws_s3_bucket.frontend.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = ["s3:GetObject"]
        Resource  = "${aws_s3_bucket.frontend.arn}/*"
      }
    ]
  })
}



