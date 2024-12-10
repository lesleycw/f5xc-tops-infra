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