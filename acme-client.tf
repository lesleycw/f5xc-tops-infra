/*
Lambda function to act as ACME client to create/update certs
*/

data "aws_s3_object" "acme_client_zip" {
  bucket = aws_s3_bucket.lambda_bucket.bucket
  key    = "acme_client${var.environment == "prod" ? "" : "_${var.environment}"}.zip"
}

resource "aws_iam_role" "acme_client_lambda_role" {
  name = "tops-acme-client-role${var.environment == "prod" ? "" : "-${var.environment}"}"

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

resource "aws_iam_policy" "acme_client_lambda_policy" {
  name        = "acme_client_lambda_policy${var.environment == "prod" ? "" : "-${var.environment}"}"
  description = "IAM Policy for the ACME Client Lambda"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["logs:CreateLogStream", "logs:PutLogEvents"],
        Resource = "arn:aws:logs:*:*:log-group:/aws/lambda/tops-acme-client*"
      },
      {
        Effect   = "Allow",
        Action   = [
          "s3:GetObject",
          "s3:HeadObject",
          "s3:PutObject"
        ],
        Resource = "${aws_s3_bucket.cert_bucket.arn}/*"
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
      {
        Effect = "Allow",
        Action = [
          "route53:ChangeResourceRecordSets",
          "route53:ListResourceRecordSets"
        ],
        Resource = [
          "arn:aws:route53:::hostedzone/${var.zone_id}"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "route53:ListHostedZones",
          "route53:GetChange"
        ],
        Resource = ["*"]
      },
      # ✅ Allow EventBridge (CloudWatch Events) to invoke the Lambda functions
      {
        Effect   = "Allow",
        Action   = ["lambda:InvokeFunction"],
        Principal = {
          "Service": "events.amazonaws.com"
        },
        Resource = [
          aws_lambda_function.acme_client_mcn_lambda.arn,
          aws_lambda_function.acme_client_app_lambda.arn,
          aws_lambda_function.acme_client_sec_lambda.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "acme_client_lambda_attach" {
  role       = aws_iam_role.acme_client_lambda_role.name
  policy_arn = aws_iam_policy.acme_client_lambda_policy.arn
}

resource "aws_cloudwatch_event_rule" "acme_daily_trigger" {
  name                = "acme-daily-trigger${var.environment == "prod" ? "" : "-${var.environment}"}"
  description         = "Triggers the ACME Client Lambda daily"
  schedule_expression = "rate(1 day)"
}

/*ACME MCN Lambda*/
resource "aws_lambda_function" "acme_client_mcn_lambda" {
  function_name    = "tops-acme-client-mcn${var.environment == "prod" ? "" : "-${var.environment}"}"
  role             = aws_iam_role.acme_client_lambda_role.arn
  runtime          = "python3.11"
  handler          = "function.lambda_handler"
  s3_bucket        = data.aws_s3_object.acme_client_zip.bucket
  s3_key           = data.aws_s3_object.acme_client_zip.key
  source_code_hash = data.aws_s3_object.acme_client_zip.etag

  timeout     = 180
  memory_size = var.lambda_memory_size

  environment {
    variables = {
      "CERT_NAME"     = "mcn-lab-wildcard${var.environment == "prod" ? "" : "-${var.environment}"}",
      "DOMAIN"        = "mcn-lab${var.environment == "prod" ? "" : "-${var.environment}"}.f5demos.com",
      "S3_BUCKET"     = aws_s3_bucket.cert_bucket.bucket,
      "EMAIL"         = var.acme_email
    }
  }

  tags = local.tags
}

resource "aws_cloudwatch_event_target" "mcn_acme_lambda_target" {
  rule      = aws_cloudwatch_event_rule.acme_daily_trigger.name
  target_id = "acme_lambda_mcn"
  arn       = aws_lambda_function.acme_client_mcn_lambda.arn
}

/*ACME App Lambda*/
resource "aws_lambda_function" "acme_client_app_lambda" {
  function_name    = "tops-acme-client-app${var.environment == "prod" ? "" : "-${var.environment}"}"
  role             = aws_iam_role.acme_client_lambda_role.arn
  runtime          = "python3.11"
  handler          = "function.lambda_handler"
  s3_bucket        = data.aws_s3_object.acme_client_zip.bucket
  s3_key           = data.aws_s3_object.acme_client_zip.key
  source_code_hash = data.aws_s3_object.acme_client_zip.etag

  timeout     = 180
  memory_size = var.lambda_memory_size

  environment {
    variables = {
      "CERT_NAME"     = "app-lab-wildcard${var.environment == "prod" ? "" : "-${var.environment}"}",
      "DOMAIN"        = "app-lab${var.environment == "prod" ? "" : "-${var.environment}"}.f5demos.com",
      "S3_BUCKET"     = aws_s3_bucket.cert_bucket.bucket,
      "EMAIL"         = var.acme_email
    }
  }

  tags = local.tags
}

resource "aws_cloudwatch_event_target" "app_acme_lambda_target" {
  rule      = aws_cloudwatch_event_rule.acme_daily_trigger.name
  target_id = "acme_lambda_app"
  arn       = aws_lambda_function.acme_client_app_lambda.arn
}

/*ACME Sec Lambda*/
resource "aws_lambda_function" "acme_client_sec_lambda" {
  function_name    = "tops-acme-client-sec${var.environment == "prod" ? "" : "-${var.environment}"}"
  role             = aws_iam_role.acme_client_lambda_role.arn
  runtime          = "python3.11"
  handler          = "function.lambda_handler"
  s3_bucket        = data.aws_s3_object.acme_client_zip.bucket
  s3_key           = data.aws_s3_object.acme_client_zip.key
  source_code_hash = data.aws_s3_object.acme_client_zip.etag

  timeout     = 180
  memory_size = var.lambda_memory_size

  environment {
    variables = {
      "CERT_NAME"     = "sec-lab-wildcard${var.environment == "prod" ? "" : "-${var.environment}"}",
      "DOMAIN"        = "sec-lab${var.environment == "prod" ? "" : "-${var.environment}"}.f5demos.com",
      "S3_BUCKET"     = aws_s3_bucket.cert_bucket.bucket,
      "EMAIL"         = var.acme_email
    }
  }

  tags = local.tags
}

resource "aws_cloudwatch_event_target" "sec_acme_lambda_target" {
  rule      = aws_cloudwatch_event_rule.acme_daily_trigger.name
  target_id = "acme_lambda_sec"
  arn       = aws_lambda_function.acme_client_sec_lambda.arn
}
