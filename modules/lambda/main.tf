resource "aws_lambda_function" "lambda" {
  function_name = var.function_name
  role          = var.lambda_role_arn
  package_type  = "Image"

  image_uri = "${var.ecr_repository_url}:${var.image_tag}"

  timeout      = var.timeout
  memory_size  = var.memory_size
  environment {
    variables = var.environment_variables
  }
  tags = var.tags
}

# Optional: CloudWatch Event Rule for Scheduled Trigger
resource "aws_cloudwatch_event_rule" "schedule" {
  count = var.trigger_type == "schedule" ? 1 : 0

  name                = "${var.function_name}-schedule"
  description         = "Trigger for Lambda function"
  schedule_expression = var.schedule_expression
  tags                = var.tags
}

resource "aws_cloudwatch_event_target" "lambda_schedule_target" {
  count = var.trigger_type == "schedule" ? 1 : 0

  rule      = aws_cloudwatch_event_rule.schedule[count.index].name
  target_id = "lambda-target"
  arn       = aws_lambda_function.lambda.arn
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  count = var.trigger_type == "schedule" ? 1 : 0

  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.schedule[count.index].arn
}

# Optional: SQS Trigger
resource "aws_lambda_event_source_mapping" "sqs" {
  count = var.trigger_type == "sqs" ? 1 : 0

  event_source_arn = var.sqs_queue_arn
  function_name    = aws_lambda_function.lambda.arn
  batch_size       = var.sqs_batch_size
  enabled          = var.sqs_enabled
}

# Variables
variable "function_name" {}
variable "lambda_role_arn" {}
variable "ecr_repository_url" {}
variable "image_tag" {
  default = "latest"
}
variable "timeout" {
  default = 60
}
variable "memory_size" {
  default = 128
}
variable "environment_variables" {
  type = map(string)
  default = {}
}

# Trigger Configuration
variable "trigger_type" {
  description = "Type of trigger for the Lambda function: 'schedule' or 'sqs'"
  type        = string
  default     = "schedule"
}

# Schedule-specific variables
variable "schedule_expression" {
  description = "Schedule expression for CloudWatch Events (e.g., 'rate(1 day)')"
  type        = string
  default     = "rate(1 day)"
}

# SQS-specific variables
variable "sqs_queue_arn" {
  description = "ARN of the SQS queue to trigger the Lambda function"
  type        = string
  default     = ""
}

variable "sqs_batch_size" {
  description = "Maximum number of messages to process from SQS at once"
  type        = number
  default     = 10
}

variable "sqs_enabled" {
  description = "Enable or disable the SQS trigger"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}