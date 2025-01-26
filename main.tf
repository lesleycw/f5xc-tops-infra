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

variable "acme_email" {
  description = "The email address to use for ACME registration"
  type        = string
  default     = ""
}

variable "mcn_wildcard_domain" {
  description = "The wildcard domain to use for the MCN lab tenant"
  type        = string
  default     = ""
}
