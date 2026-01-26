variable "project" {
  description = "Project name"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "private_db_subnet_ids" {
  description = "Private database subnet IDs from the network layer"
  type        = list(string)
}

variable "app_sg_id" {
  description = "Security group ID of the App layer"
  type        = string
}