# ALB
output "alb_dns_name" {
  description = "DNS name of the ALB"
  value       = aws_lb.this.dns_name
}

# ALB Zone ID
output "alb_zone_id" {
  description = "Zone ID of the ALB"
  value       = aws_lb.this.zone_id
}

# Target Group
output "target_group_arn" {
  description = "ARN of the target group"
  value       = aws_lb_target_group.app.arn
}
