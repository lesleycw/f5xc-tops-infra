resource "aws_iam_policy" "utility_lambda_policy" {
  name        = "utility-lambda-policy${var.environment == "prod" ? "" : "-${var.environment}"}"
  description = "IAM Policy for the Token Refresh Lambda Functions"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["logs:CreateLogStream", "logs:PutLogEvents"],
        Resource = "arn:aws:logs:*:*:log-group:/aws/lambda/tops-*"
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

data "aws_s3_object" "user_create_zip" {
  bucket = module.lambda_bucket.bucket_name
  key    = "user_create${var.environment == "prod" ? "" : "_${var.environment}"}.zip"
}

module "user_create_lambda" {
    count                = length(data.aws_s3_object.user_create_zip.id) > 0 ? 1 : 0
    source                = "./modules/lambda"
    function_name         = "tops-user-create${var.environment == "prod" ? "" : "-${var.environment}"}"
    lambda_role_arn       = aws_iam_role.lambda_execution_role.arn
    lambda_policy_arn     = aws_iam_policy.utility_lambda_policy.arn
    s3_bucket             = data.aws_s3_object.user_create_zip.bucket
    s3_key                = data.aws_s3_object.user_create_zip.key
    source_code_hash      = data.aws_s3_object.user_create_zip.etag
    runtime               = "python3.11"
    handler               = "function.lambda_handler"
    tags                  = local.tags
}

data "aws_s3_object" "user_remove_zip" {
  bucket = module.lambda_bucket.bucket_name
  key    = "user_remove${var.environment == "prod" ? "" : "_${var.environment}"}.zip"
}

module "user_remove_lambda" {
    count                = length(data.aws_s3_object.user_remove_zip.id) > 0 ? 1 : 0
    source                = "./modules/lambda"
    function_name         = "tops-user-remove${var.environment == "prod" ? "" : "-${var.environment}"}"
    lambda_role_arn       = aws_iam_role.lambda_execution_role.arn
    lambda_policy_arn     = aws_iam_policy.utility_lambda_policy.arn
    s3_bucket             = data.aws_s3_object.user_remove_zip.bucket
    s3_key                = data.aws_s3_object.user_remove_zip.key
    source_code_hash      = data.aws_s3_object.user_remove_zip.etag
    runtime               = "python3.11"
    handler               = "function.lambda_handler"
    tags                  = local.tags
}

data "aws_s3_object" "ns_create_zip" {
  bucket = module.lambda_bucket.bucket_name
  key    = "ns_create${var.environment == "prod" ? "" : "_${var.environment}"}.zip"
}

module "ns_create_lambda" {
    count                = length(data.aws_s3_object.ns_create_zip.id) > 0 ? 1 : 0
    source                = "./modules/lambda"
    function_name         = "tops-user-remove${var.environment == "prod" ? "" : "-${var.environment}"}"
    lambda_role_arn       = aws_iam_role.lambda_execution_role.arn
    lambda_policy_arn     = aws_iam_policy.utility_lambda_policy.arn
    s3_bucket             = data.aws_s3_object.ns_create_zip.bucket
    s3_key                = data.aws_s3_object.ns_create_zip.key
    source_code_hash      = data.aws_s3_object.ns_create_zip.etag
    runtime               = "python3.11"
    handler               = "function.lambda_handler"
    tags                  = local.tags
}

data "aws_s3_object" "ns_remove_zip" {
  bucket = module.lambda_bucket.bucket_name
  key    = "ns_remove${var.environment == "prod" ? "" : "_${var.environment}"}.zip"
}

module "ns_remove_lambda" {
    count                = length(data.aws_s3_object.ns_remove_zip.id) > 0 ? 1 : 0
    source                = "./modules/lambda"
    function_name         = "tops-user-remove${var.environment == "prod" ? "" : "-${var.environment}"}"
    lambda_role_arn       = aws_iam_role.lambda_execution_role.arn
    lambda_policy_arn     = aws_iam_policy.utility_lambda_policy.arn
    s3_bucket             = data.aws_s3_object.ns_remove_zip.bucket
    s3_key                = data.aws_s3_object.ns_remove_zip.key
    source_code_hash      = data.aws_s3_object.ns_remove_zip.etag
    runtime               = "python3.11"
    handler               = "function.lambda_handler"
    tags                  = local.tags
}