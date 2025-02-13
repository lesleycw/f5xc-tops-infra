terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "remote" {
    organization = "f5xc-tenant-ops"

    workspaces {
      name = "tops-infra-${var.environment}"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
    tags = {
        Environment = var.environment
        ManagedBy   = "Terraform"
        Owner       = "f5xc-tenant-ops"
    }
}

data "aws_caller_identity" "current" {}

/*
Common Lambda Resources 
*/
resource "aws_iam_role" "lambda_execution_role" {
  name = "tops-lambda-execution-role${var.environment == "prod" ? "" : "-${var.environment}"}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_s3_bucket" "lambda_bucket" {
  bucket        = "tops-lambda-bucket${var.environment == "prod" ? "" : "-${var.environment}"}"
  force_destroy = true

  lifecycle {
    prevent_destroy = true
  }

  tags = local.tags
}

/* 
Vars 
*/

variable "aws_region" {
  description = "AWS region for the S3 bucket"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "The branch name or workspace name to suffix resource names"
  type        = string
}

variable "lambda_timeout" {
  description = "The timeout for the Lambda function (in seconds)"
  type        = number
  default     = 60
}

variable "lambda_memory_size" {
  description = "The memory allocated to the Lambda function (in MB)"
  type        = number
  default     = 128
}

variable "acme_email" {
  description = "The email address to use for ACME registration"
  type        = string
}

variable "zone_id" {
  description = "The Route 53 zone ID for the wildcard domain"
  type        = string
}

variable "udf_principal_org_path" {
  description = "The principal org path for UDF"
  type        = string
}
