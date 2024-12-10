variable "aws_region" {
  description = "AWS region for the S3 bucket"
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
  default     = ""
}

variable "environment" {
  description = "The branch name or workspace name to suffix resource names"
  type        = string
  default     = ""
}