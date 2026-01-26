variable "project" {
  description = "The project name"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "certificate_arn" {
  description = "The ARN of the ACM certificate to use with the ALB"
  type        = string
}

variable "secret_name" {
  description = "Name of the existing Secrets Manager secret"
  type        = string
}