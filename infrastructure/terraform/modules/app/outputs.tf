# ALB
output "alb_sg_id" {
  description = "Security group ID for the ALB"
  value = aws_security_group.alb.id
}

# EC2
output "ec2_sg_id" {
  description = "Security group ID for the EC2 instances"
  value = aws_security_group.ec2.id
}

# ALB
output "alb_dns_name" {
  description = "DNS name of the ALB"
  value = aws_lb.this.dns_name
}

# Target Group
output "target_group_arn" {
  description = "ARN of the target group"
  value = aws_lb_target_group.app.arn
}

# EC2 IAM Role
output "ec2_role_arn" {
  description = "ARN of the EC2 IAM role attached to app instances"
  value       = aws_iam_role.ssm_role.arn
}

# S3 Website Endpoint
output "s3_website_endpoint" {
  description = "Frontend static website URL"
  value       = aws_s3_bucket_website_configuration.frontend.website_endpoint
}