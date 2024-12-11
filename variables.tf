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
  description = "The token to use for the MCN Lab Tenant"
  type        = string
  sensitive   = true
  default     = ""
}