variable "env" {
  type = string
  validation {
    condition     = contains(["prod", "stage", "test"], var.env)
    error_message = "`env` must be either `prod` or `stage` or `test`"
  }
}

variable "project_id" {
  description = "ludo project id"
  type        = string
  default     = "vast-descent-432100-q4"
}

variable "region" {
  description = "ludo project region"
  type        = string
  default     = "us-west1"
}

variable "availability_zone" {
  description = "ludo availability zone"
  type        = string
  default     = "us-west1-b"
}

variable "db_name" {
  description = "ludo db name"
  type        = string
}

variable "db_username" {
  description = "ludo db user name"
  type        = string
}

variable "db_password" {
  description = "ludo db password"
  type        = string
}

variable "app_image" {
  description = "ludo app docker image"
  type        = string

  validation {
    condition     = length(var.app_image) > 0
    error_message = "app_image must not be empty string"
  }
}

variable "frontend_url" {
  description = "ludo frontend url"
  type        = string
}

variable "app_port" {
  description = "port of the app"
  type        = number
}

variable "iam_member_emails" {
  description = "ludo iam member emails"
  type        = list(string)
}

variable "disk_size_gb" {
  description = "database disk size(GB)"
  type        = number
}
