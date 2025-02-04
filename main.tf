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

module "lambda_bucket" {
  source      = "./modules/bucket"
  bucket_name = "tops-lambda-bucket${var.environment == "prod" ? "" : "-${var.environment}"}"

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

variable "acme_email" {
  description = "The email address to use for ACME registration"
  type        = string
}

variable "zone_id" {
  description = "The Route 53 zone ID for the wildcard domain"
  type        = string
}
