# ALB
output "alb_dns_name" {
  description = "DNS name of the ALB"
  value       = aws_lb.this.dns_name
}

output "alb_zone_id"  { 
  description = "Zone ID of the ALB"
  value = aws_lb.this.zone_id 
}

# Target Group
output "target_group_arn" {
  description = "ARN of the target group"
  value       = aws_lb_target_group.app.arn
}

# S3 Website Endpoint
output "s3_website_endpoint" {
  description = "Frontend static website URL"
  value       = aws_s3_bucket_website_configuration.frontend.website_endpoint
}