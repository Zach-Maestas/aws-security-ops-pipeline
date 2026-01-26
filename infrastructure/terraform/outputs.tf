output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value = module.app.alb_dns_name
}

output "s3_website_endpoint" {
  description = "Frontend static website URL"
  value = module.app.s3_website_endpoint
}
