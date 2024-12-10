module "cert_bucket" {
  source      = "./modules/bucket"
  bucket_name = "tops-cert-bucket-${var.environment}"
  tags = local.tags
}

module "ecr" {
  source          = "./modules/ecr"
  repository_name = "tops-cert-mgmt-${var.environment}"
  tags = local.tags
}

output "cert_bucket_name" {
  value = module.cert_bucket.cert_bucket_name
}

output "cert_bucket_arn" {
  value = module.cert_bucket.cert_bucket_arn
}

output "cert_ecr_url" {
  description = "The URL of the ECR repository"
  value       = module.ecr.repository_url
}

output "cert_ecr_arn" {
  description = "The ARN of the ECR repository"
  value       = module.ecr.repository_arn
}