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
      name = "tops-infra-dev"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

resource "aws_s3_bucket" "this_bucket" {
  bucket        = "tops-cert-bucket-${var.environment}"
  force_destroy = true

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = "f5xc-tenant-ops"
  }
}

resource "aws_s3_bucket_acl" "this_bucket_acl" {
  bucket = aws_s3_bucket.this_bucket.id
  acl    = "private"
}