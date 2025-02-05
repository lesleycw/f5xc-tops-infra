/*
UDF Worker Lambda
*/
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
  stream_view_type = "NEW_AND_OLD_IMAGES"  # ✅ Captures both inserts & deletes
}

data "aws_s3_object" "udf_worker_zip" {
  bucket = aws_s3_bucket.lambda_bucket.bucket
  key    = "udf_worker${var.environment == "prod" ? "" : "_${var.environment}"}.zip"
}

resource "aws_iam_role" "udf_worker_lambda_role" {
  name = "tops-udf-worker-role${var.environment == "prod" ? "" : "-${var.environment}"}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "udf_worker_lambda_policy" {
  name        = "udf_worker_lambda_policy${var.environment == "prod" ? "" : "-${var.environment}"}"
  description = "IAM Policy for the UDF Worker Lambda"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      # ✅ Allow Lambda to log
      {
        Effect   = "Allow",
        Action   = ["logs:CreateLogStream", "logs:PutLogEvents"],
        Resource = "arn:aws:logs:*:*:log-group:/aws/lambda/tops-udf-worker*"
      },

      # ✅ Allow Lambda to interact with DynamoDB
      {
        Effect   = "Allow",
        Action   = [
          "dynamodb:GetRecords",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DescribeStream" 
        ],
        Resource = aws_dynamodb_table.lab_deployment_state.arn
      },

      # ✅ Allow Lambda to invoke other Lambda functions
      {
        Effect   = "Allow",
        Action   = ["lambda:InvokeFunction"],
        Resource = [
          "arn:aws:lambda:*:*:function:tops-user-create*",
          "arn:aws:lambda:*:*:function:tops-ns-create*",
          "arn:aws:lambda:*:*:function:tops-helper*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "udf_worker_lambda_attach" {
  role       = aws_iam_role.udf_worker_lambda_role.name
  policy_arn = aws_iam_policy.udf_worker_lambda_policy.arn
}

resource "aws_lambda_function" "udf_worker_lambda" {
  function_name    = "tops-udf-worker${var.environment == "prod" ? "" : "-${var.environment}"}"
  role             = aws_iam_role.udf_worker_lambda_role.arn
  runtime          = "python3.11"
  handler          = "function.lambda_handler"
  s3_bucket        = data.aws_s3_object.udf_worker_zip.bucket
  s3_key           = data.aws_s3_object.udf_worker_zip.key
  source_code_hash = data.aws_s3_object.udf_worker_zip.etag

  environment {
    variables = {
      DEPLOYMENT_STATE_TABLE      = aws_dynamodb_table.lab_deployment_state.name
      LAB_CONFIGURATION_TABLE     = aws_dynamodb_table.lab_configuration.name
    }
  }

  timeout     = var.lambda_timeout
  memory_size = var.lambda_memory_size

  tags = local.tags
}

resource "aws_lambda_event_source_mapping" "udf_worker_dynamodb_trigger" {
  function_name     = aws_lambda_function.udf_worker_lambda.arn
  event_source_arn  = aws_dynamodb_table.lab_deployment_state.stream_arn
  starting_position = "LATEST"
  batch_size        = 1
  enabled           = true

  filter_criteria {
    filter {
      pattern = "{ \"eventName\": [\"INSERT\"] }"
    }
  }
}

/*
UDF Cleanup Lambda
*/

data "aws_s3_object" "udf_cleanup_zip" {
  bucket = aws_s3_bucket.lambda_bucket.bucket
  key    = "udf_cleanup${var.environment == "prod" ? "" : "_${var.environment}"}.zip"
}

resource "aws_iam_role" "udf_cleanup_lambda_role" {
  name = "tops-udf-cleanup-role${var.environment == "prod" ? "" : "-${var.environment}"}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}
resource "aws_iam_policy" "udf_cleanup_lambda_policy" {
  name        = "cleanup_lambda_policy${var.environment == "prod" ? "" : "-${var.environment}"}"
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
        Action   = ["lambda:InvokeFunction"],
        Resource = [
          "arn:aws:lambda:*:*:function:tops-user-remove*",
          "arn:aws:lambda:*:*:function:tops-ns-remove*"
        ]
      },
      {
        Effect   = "Allow",
        Action   = ["logs:CreateLogStream", "logs:PutLogEvents"],
        Resource = "arn:aws:logs:*:*:log-group:/aws/lambda/tops-udf-cleanup*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "udf_cleanup_lambda_attach" {
  role       = aws_iam_role.udf_cleanup_lambda_role.name  
  policy_arn = aws_iam_policy.udf_cleanup_lambda_policy.arn
}

resource "aws_lambda_function" "udf_cleanup_lambda" {
  function_name    = "tops-udf-cleanup${var.environment == "prod" ? "" : "-${var.environment}"}"
  role             = aws_iam_role.udf_cleanup_lambda_role.arn
  runtime          = "python3.11"
  handler          = "function.lambda_handler"
  s3_bucket        = data.aws_s3_object.udf_cleanup_zip.bucket
  s3_key           = data.aws_s3_object.udf_cleanup_zip.key
  source_code_hash = data.aws_s3_object.udf_cleanup_zip.etag

  timeout     = var.lambda_timeout
  memory_size = var.lambda_memory_size

  tags = local.tags
}

resource "aws_lambda_event_source_mapping" "udf_cleanup_dynamodb_trigger" {
  function_name     = aws_lambda_function.udf_cleanup_lambda.arn
  event_source_arn  = aws_dynamodb_table.lab_deployment_state.stream_arn
  starting_position = "LATEST"
  batch_size        = 1
  enabled           = true

  filter_criteria {
    filter {
      pattern = "{ \"eventName\": [\"REMOVE\"] }"
    }
  }
}






