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

module "cert_bucket" {
  source      = "./modules/bucket"
  bucket_name = "tops-cert-bucket-${var.environment}"
  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = "f5xc-tenant-ops"
  }
}

output "cert_bucket_name" {
  value = module.common_s3.cert_bucket_name
}

output "cert_bucket_arn" {
  value = module.common_s3.cert_bucket_arn
}