variable "aws_region" {
  description = "AWS region for the S3 bucket"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "The branch name or workspace name to suffix resource names"
  type        = string
  default     = ""
}

variable "mcn_lab_token" {
  description = "Access token for the MCN Lab Tenant"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.mcn_lab_token) > 0
    error_message = "The mcn_lab_token variable must not be empty."
  }
}