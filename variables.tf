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
}

variable "app_lab_token" {
  description = "Access token for the App Lab Tenant"
  type        = string
  sensitive   = true
}

variable "sec_lab_token" {
  description = "Access token for the Sec Lab Tenant"
  type        = string
  sensitive   = true
}