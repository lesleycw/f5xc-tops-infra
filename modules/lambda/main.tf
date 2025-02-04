# Lambda Function
resource "aws_lambda_function" "lambda" {
  function_name    = var.function_name
  role             = var.lambda_role_arn
  runtime          = var.runtime
  handler          = var.handler
  s3_bucket        = var.s3_bucket
  s3_key           = var.s3_key
  source_code_hash = var.source_code_hash

  timeout     = var.timeout
  memory_size = var.memory_size

  environment {
    variables = var.environment_variables
  }

  tags = var.tags
}

# Attach IAM Policy
resource "aws_iam_role_policy_attachment" "lambda_policy_attach" {
  role       = var.lambda_role_arn
  policy_arn = var.lambda_policy_arn
}

# -------------------- CloudWatch Scheduled Trigger (Cron) --------------------

resource "aws_cloudwatch_event_rule" "schedule" {
  count = var.schedule_expression != null ? 1 : 0

  name                = "${var.function_name}-schedule"
  description         = "Scheduled trigger for ${var.function_name}"
  schedule_expression = var.schedule_expression
}

resource "aws_cloudwatch_event_target" "lambda_schedule_target" {
  count = var.schedule_expression != null ? 1 : 0

  rule      = aws_cloudwatch_event_rule.schedule[0].name
  target_id = "lambda-target"
  arn       = aws_lambda_function.lambda.arn
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  count = var.schedule_expression != null ? 1 : 0

  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.schedule[0].arn
}

# -------------------- SQS Trigger --------------------

resource "aws_lambda_event_source_mapping" "sqs" {
  function_name    = aws_lambda_function.lambda.arn
  event_source_arn = var.sqs_queue_arn
  batch_size       = var.sqs_batch_size
  enabled          = var.sqs_queue_arn != null ? true : false
}

# -------------------- DynamoDB Stream Trigger --------------------

resource "aws_lambda_event_source_mapping" "dynamodb_stream" {
  function_name     = aws_lambda_function.lambda.arn
  event_source_arn  = var.dynamodb_stream_arn
  starting_position = "LATEST"
  
  # Enable only if the ARN is known
  enabled = var.dynamodb_stream_arn != null ? true : false
}

# -------------------- Outputs --------------------
output "function_arn" {
  description = "The ARN of the created Lambda function"
  value       = aws_lambda_function.lambda.arn
}
