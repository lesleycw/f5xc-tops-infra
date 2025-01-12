module "token_refresh_ecr" {
  source          = "./modules/ecr"
  repository_name = "tops-token-refresh-${var.environment}"
  tags = local.tags
}

output "token_refresh_ecr_url" {
  description = "The URL of the ECR repository"
  value       = module.token_refresh_ecr.repository_url
}

output "token_refresh_ecr_arn" {
  description = "The ARN of the ECR repository"
  value       = module.token_refresh_ecr.repository_arn
}