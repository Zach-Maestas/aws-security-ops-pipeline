variable "project" {
  description = "Project name for tagging resources"
  type        = string
}

variable "domain_name" {
  description = "Domain name for the ACM certificate (e.g. api.example.com)"
  type        = string
}

variable "hosted_zone_id" {
  description = "The Route 53 Hosted Zone ID to use for DNS validation"
  type        = string
}

variable "alb_dns_name" {
  description = "The DNS name of the Application Load Balancer"
  type        = string
}
