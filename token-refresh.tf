data "aws_s3_object" "token_refresh_zip" {
  bucket = module.lambda_bucket.bucket_name
  key    = "token_refresh${var.environment == "prod" ? "" : "_${var.environment}"}.zip"
}

module "token_refresh_mcn_lambda" {
  source                = "./modules/lambda"
  function_name         = "tops-token-refresh-mcn${var.environment == "prod" ? "" : "-${var.environment}"}"
  lambda_role_arn       = aws_iam_role.lambda_execution_role.arn
  s3_bucket             = data.aws_s3_object.token_refresh_zip.bucket
  s3_key                = data.aws_s3_object.token_refresh_zip.key
  source_code_hash      = data.aws_s3_object.token_refresh_zip.etag
  runtime               = "python3.11"
  handler               = "function.lambda_handler"
  environment_variables = {
    "SSM_BASE_PATH" = "/tenantOps${var.environment == "prod" ? "" : "-${var.environment}"}/mcn-lab"
  }
  trigger_type          = "schedule"
  schedule_expression   = "rate(1 day)"
  tags                  = local.tags
}

module "token_refresh_sec_lambda" {
  source                = "./modules/lambda"
  function_name         = "tops-token-refresh-sec${var.environment == "prod" ? "" : "-${var.environment}"}"
  lambda_role_arn       = aws_iam_role.lambda_execution_role.arn
  s3_bucket             = data.aws_s3_object.token_refresh_zip.bucket
  s3_key                = data.aws_s3_object.token_refresh_zip.key
  source_code_hash      = data.aws_s3_object.token_refresh_zip.etag
  runtime               = "python3.11"
  handler               = "function.lambda_handler"
  environment_variables = {
    "SSM_BASE_PATH" = "/tenantOps${var.environment == "prod" ? "" : "-${var.environment}"}/sec-lab"
  }
  trigger_type          = "schedule"
  schedule_expression   = "rate(1 day)"
  tags                  = local.tags
}

module "token_refresh_app_lambda" {
  source                = "./modules/lambda"
  function_name         = "tops-token-refresh-app${var.environment == "prod" ? "" : "-${var.environment}"}"
  lambda_role_arn       = aws_iam_role.lambda_execution_role.arn
  s3_bucket             = data.aws_s3_object.token_refresh_zip.bucket
  s3_key                = data.aws_s3_object.token_refresh_zip.key
  source_code_hash      = data.aws_s3_object.token_refresh_zip.etag
  runtime               = "python3.11"
  handler               = "function.lambda_handler"
  environment_variables = {
    "SSM_BASE_PATH" = "/tenantOps${var.environment == "prod" ? "" : "-${var.environment}"}/app-lab"
  }
  trigger_type          = "schedule"
  schedule_expression   = "rate(1 day)"
  tags                  = local.tags
}