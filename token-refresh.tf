/*
Lambda function to refresh tenant access tokens
*/
data "aws_s3_object" "token_refresh_zip" {
  bucket = module.lambda_bucket.bucket_name
  key    = "token_refresh${var.environment == "prod" ? "" : "_${var.environment}"}.zip"
}

resource "aws_iam_policy" "token_refresh_lambda_policy" {
  name        = "TokenRefreshLambdaPolicy"
  description = "IAM Policy for the Token Refresh Lambda Functions"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["logs:CreateLogStream", "logs:PutLogEvents"],
        Resource = "arn:aws:logs:*:*:log-group:/aws/lambda/tops-token-refresh*"
      },
      {
        Effect = "Allow",
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ],
        Resource = "arn:aws:ssm:us-east-1:317124676658:parameter/*"
      },
    ]
  })
}

module "token_refresh_mcn_lambda" {
  source                = "./modules/lambda"
  function_name         = "tops-token-refresh-mcn${var.environment == "prod" ? "" : "-${var.environment}"}"
  lambda_role_arn       = aws_iam_role.lambda_execution_role.arn
  lambda_policy_arn     = aws_iam_policy.token_refresh_lambda_policy.arn
  s3_bucket             = data.aws_s3_object.token_refresh_zip.bucket
  s3_key                = data.aws_s3_object.token_refresh_zip.key
  source_code_hash      = data.aws_s3_object.token_refresh_zip.etag
  runtime               = "python3.11"
  handler               = "function.lambda_handler"
  environment_variables = {
    "SSM_BASE_PATH" = "/tenantOps${var.environment == "prod" ? "" : "-${var.environment}"}/mcn-lab"
  }
  schedule_expression   = "cron(0 1 * * ? *)"
  tags                  = local.tags
}

module "token_refresh_sec_lambda" {
  source                = "./modules/lambda"
  function_name         = "tops-token-refresh-sec${var.environment == "prod" ? "" : "-${var.environment}"}"
  lambda_role_arn       = aws_iam_role.lambda_execution_role.arn
  lambda_policy_arn     = aws_iam_policy.token_refresh_lambda_policy.arn
  s3_bucket             = data.aws_s3_object.token_refresh_zip.bucket
  s3_key                = data.aws_s3_object.token_refresh_zip.key
  source_code_hash      = data.aws_s3_object.token_refresh_zip.etag
  runtime               = "python3.11"
  handler               = "function.lambda_handler"
  environment_variables = {
    "SSM_BASE_PATH" = "/tenantOps${var.environment == "prod" ? "" : "-${var.environment}"}/sec-lab"
  }
  schedule_expression   = "cron(0 1 * * ? *)"
  tags                  = local.tags
}

module "token_refresh_app_lambda" {
  source                = "./modules/lambda"
  function_name         = "tops-token-refresh-app${var.environment == "prod" ? "" : "-${var.environment}"}"
  lambda_role_arn       = aws_iam_role.lambda_execution_role.arn
  lambda_policy_arn     = aws_iam_policy.token_refresh_lambda_policy.arn
  s3_bucket             = data.aws_s3_object.token_refresh_zip.bucket
  s3_key                = data.aws_s3_object.token_refresh_zip.key
  source_code_hash      = data.aws_s3_object.token_refresh_zip.etag
  runtime               = "python3.11"
  handler               = "function.lambda_handler"
  environment_variables = {
    "SSM_BASE_PATH" = "/tenantOps${var.environment == "prod" ? "" : "-${var.environment}"}/app-lab"
  }
  schedule_expression   = "cron(0 1 * * ? *)"
  tags                  = local.tags
}
