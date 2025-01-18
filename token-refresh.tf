module "token_refresh_ecr" {
  source          = "./modules/ecr"
  repository_name = "tops-token-refresh${var.environment == "prod" ? "" : "-${var.environment}"}"
  tags = local.tags
}

output "token_refresh_ecr_url" {
  description = "The URL of the ECR repository"
  value       = module.token_refresh_ecr.repository_url
}

/* This can be removed */
output "token_refresh_ecr_arn" {
  description = "The ARN of the ECR repository"
  value       = module.token_refresh_ecr.repository_arn
}

module "token_refresh_mcn_lambda" {
  source                = "./modules/lambda"
  function_name         = "tops-token-refresh-mcn${var.environment == "prod" ? "" : "-${var.environment}"}"
  lambda_role_arn       = aws_iam_role.lambda_execution_role.arn
  ecr_repository_url    = module.token_refresh_ecr.repository_url
  environment_variables = {
    "key" = "test"
  }
  trigger_type          = "schedule"
  schedule_expression   = "rate(1 day)"
  tags                  = local.tags
}