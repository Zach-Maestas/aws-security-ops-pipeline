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

variable "db_name" {
  description = "Name of the database"
  type        = string
  default     = "appdb"
}

variable "db_admin_username" {
  description = "Username for the database admin"
  type        = string
  default     = "administrator"
}

variable "db_app_username" {
  description = "Username for the application database user"
  type        = string
  default     = "appuser"
}

variable "db_port" {
  description = "Name of the database"
  type        = number
  default     = 5432
}