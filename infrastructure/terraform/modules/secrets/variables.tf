variable "project" {
  description = "The project name"
  type        = string
}

variable "db_app_username" {
  description = "Username for the application database role (least privilege)"
  type        = string
  default     = "app_items_rw"
}