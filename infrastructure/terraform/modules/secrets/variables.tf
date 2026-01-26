variable "secret_name" {
  description = "Name of the existing Secrets Manager secret"
  type        = string
}

variable "ec2_role_arn" {
  description = "ARN of the EC2 instance role allowed to access the secret"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for source restriction"
  type        = string
}
