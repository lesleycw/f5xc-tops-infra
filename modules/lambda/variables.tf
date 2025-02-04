variable "function_name" {
  description = "The name of the Lambda function"
  type        = string
}

variable "lambda_role_arn" {
  description = "The IAM role ARN for the Lambda function (must be provided)"
  type        = string
}

variable "lambda_policy_arn" {
  description = "The IAM policy ARN to attach to the Lambda execution role (must be provided)"
  type        = string
}

variable "s3_bucket" {
  description = "The S3 bucket containing the Lambda ZIP package"
  type        = string
}

variable "s3_key" {
  description = "The S3 key of the Lambda ZIP package"
  type        = string
}

variable "source_code_hash" {
  description = "The base64-encoded SHA256 hash of the Lambda ZIP package"
  type        = string
}

variable "runtime" {
  description = "The runtime for the Lambda function (e.g., python3.11)"
  type        = string
  default     = "python3.11"
}

variable "handler" {
  description = "The handler for the Lambda function (e.g., function.lambda_handler)"
  type        = string
  default     = "function.lambda_handler"
}

variable "timeout" {
  description = "The timeout for the Lambda function (in seconds)"
  type        = number
  default     = 60
}

variable "memory_size" {
  description = "The amount of memory allocated to the Lambda function (in MB)"
  type        = number
  default     = 128
}

variable "environment_variables" {
  description = "Environment variables for the Lambda function"
  type        = map(string)
  default     = {}
}

# Optional Trigger Variables
variable "schedule_expression" {
  description = "Schedule expression for CloudWatch Events (e.g., 'rate(1 day)')"
  type        = string
  default     = null
}

variable "sqs_queue_arn" {
  description = "ARN of the SQS queue to trigger the Lambda function (optional)"
  type        = string
  default     = null
}

variable "sqs_batch_size" {
  description = "Maximum number of messages to process from SQS at once"
  type        = number
  default     = 1
}

variable "dynamodb_stream_arn" {
  description = "ARN of the DynamoDB Stream to trigger the Lambda function (optional)"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}