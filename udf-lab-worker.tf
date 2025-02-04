resource "aws_dynamodb_table" "lab_deployment_state" {
  name         = "tops-lab-deployment-state${var.environment == "prod" ? "" : "-${var.environment}"}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "deployment_id"

  attribute {
    name = "deployment_id"
    type = "S"
  }

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  stream_enabled   = true
  stream_view_type = "OLD_IMAGE"
}

resource "aws_sqs_queue" "udf_worker_queue" {
  name                      = "tops-udf-worker-queue${var.environment == "prod" ? "" : "-${var.environment}"}"
  message_retention_seconds = 86400
  visibility_timeout_seconds = 60
  delay_seconds             = 0
  receive_wait_time_seconds = 10
}


data "aws_s3_object" "udf_worker_zip" {
  bucket = module.lambda_bucket.bucket_name
  key    = "udf_worker${var.environment == "prod" ? "" : "_${var.environment}"}.zip"
}

resource "aws_iam_policy" "udf_worker_lambda_policy" {
  name        = "udf_worker_lambda_policy${var.environment == "prod" ? "" : "-${var.environment}"}"
  description = "IAM Policy for the UDF Worker Lambda"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["logs:CreateLogStream", "logs:PutLogEvents"],
        Resource = "arn:aws:logs:*:*:log-group:/aws/lambda/tops-udf-worker*"
      },
      {
        Effect   = "Allow",
        Action   = ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes"],
        Resource = aws_sqs_queue.udf_worker_queue.arn
      },
      {
        Effect   = "Allow",
        Action   = "dynamodb:GetRecords",
        Resource = aws_dynamodb_table.lab_configuration.arn
      },
      {
        Effect   = "Allow",
        Action   = ["lambda:InvokeFunction"],
        Resource = compact([
          try(module.user_create_lambda[0].function_arn, null),
          try(module.ns_create_lambda[0].function_arn, null)
        ])
      }
    ]
  })
}

module "udf_worker_lambda" {
  count                = length(data.aws_s3_object.udf_worker_zip.id) > 0 ? 1 : 0
  source                = "./modules/lambda"
  function_name         = "tops-udf-worker${var.environment == "prod" ? "" : "-${var.environment}"}"
  lambda_role_arn       = aws_iam_role.lambda_execution_role.arn
  lambda_policy_arn     = aws_iam_policy.udf_worker_lambda_policy.arn
  s3_bucket             = data.aws_s3_object.udf_worker_zip.bucket
  s3_key                = data.aws_s3_object.udf_worker_zip.key
  source_code_hash      = data.aws_s3_object.udf_worker_zip.etag
  runtime               = "python3.11"
  handler               = "function.lambda_handler"
  sqs_queue_arn         = aws_sqs_queue.udf_worker_queue.arn
  sqs_batch_size        = 1
  sqs_enabled           = true
  tags                  = local.tags
}

data "aws_s3_object" "udf_cleanup_zip" {
  bucket = module.lambda_bucket.bucket_name
  key    = "udf_cleanup${var.environment == "prod" ? "" : "_${var.environment}"}.zip"
}

resource "aws_iam_policy" "udf_cleanup_lambda_policy" {
  name        = "CleanupLambdaPolicy"
  description = "Allows Lambda to read from DynamoDB streams and invoke other Lambdas"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "dynamodb:DescribeStream",
        Resource = aws_dynamodb_table.lab_deployment_state.stream_arn
      },
      {
        Effect   = "Allow",
        Action   = "dynamodb:GetRecords",
        Resource = aws_dynamodb_table.lab_deployment_state.stream_arn
      },
      {
        Effect   = "Allow",
        Action   = "dynamodb:GetShardIterator",
        Resource = aws_dynamodb_table.lab_deployment_state.stream_arn
      },
      {
        Effect   = "Allow",
        Action   = "lambda:InvokeFunction",
        Resource = [
          module.user_delete_lambda.function_arn,
          module.ns_remove_lambda.function_arn
        ]
      },
      {
        Effect   = "Allow",
        Action   = ["logs:CreateLogStream", "logs:PutLogEvents"],
        Resource = "arn:aws:logs:*:*:log-group:/aws/lambda/tops-udf-cleanup*"
      },
    ]
  })
}

module "udf_cleanup_lambda" {
  count                = length(data.aws_s3_object.udf_cleanup_zip.id) > 0 ? 1 : 0
  source                = "./modules/lambda"
  function_name         = "tops-udf-cleanup${var.environment == "prod" ? "" : "-${var.environment}"}"
  lambda_role_arn       = aws_iam_role.lambda_execution_role.arn
  lambda_policy_arn     = aws_iam_policy.udf_cleanup_lambda_policy.arn
  s3_bucket             = data.aws_s3_object.udf_cleanup_zip.bucket
  s3_key                = data.aws_s3_object.udf_cleanup_zip.key
  source_code_hash      = data.aws_s3_object.udf_cleanup_zip.etag
  runtime               = "python3.11"
  handler               = "function.lambda_handler"
  dynamodb_stream_arn   = aws_dynamodb_table.lab_deployment_state.stream_arn
  tags                  = local.tags
}







