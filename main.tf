terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
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
