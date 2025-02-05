/*
S3 Bucket to store all generated certificates
*/

resource "aws_s3_bucket" "cert_bucket" {
  bucket        = "tops-cert-bucket${var.environment == "prod" ? "" : "-${var.environment}"}"
  force_destroy = true

  lifecycle {
    prevent_destroy = true
  }

  tags = local.tags
}

output "cert_bucket_name" {
  value = aws_s3_bucket.cert_bucket.bucket
}

output "cert_bucket_arn" {
  value = aws_s3_bucket.cert_bucket.arn
}

/*
Lambda function to manage certificates in tenants
*/

data "aws_s3_object" "cert_mgmt_zip" {
  bucket = aws_s3_bucket.lambda_bucket.bucket
  key    = "cert_mgmt${var.environment == "prod" ? "" : "_${var.environment}"}.zip"
}

resource "aws_iam_role" "cert_mgmt_lambda_role" {
  name = "tops-cert-mgmt-role${var.environment == "prod" ? "" : "-${var.environment}"}"

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

resource "aws_iam_policy" "cert_mgmt_lambda_policy" {
  name        = "cert_mgmt_lambda_policy${var.environment == "prod" ? "" : "-${var.environment}"}"
  description = "IAM Policy for the Cert Management Lambda"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["logs:CreateLogStream", "logs:PutLogEvents", "logs:CreateLogGroup"],
        Resource = "arn:aws:logs:*:*:log-group:/aws/lambda/tops-cert-mgmt*"
      },
      {
        Effect   = "Allow",
        Action   = ["s3:GetObject", "s3:PutObject"],
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
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cert_mgmt_lambda_attach" {
  role       = aws_iam_role.cert_mgmt_lambda_role.name
  policy_arn = aws_iam_policy.cert_mgmt_lambda_policy.arn
}

resource "aws_lambda_function" "cert_mgmt_mcn_lambda" {
  function_name    = "tops-cert-mgmt-mcn${var.environment == "prod" ? "" : "-${var.environment}"}"
  role             = aws_iam_role.cert_mgmt_lambda_role.arn
  runtime          = "python3.11"
  handler          = "function.lambda_handler"
  s3_bucket        = data.aws_s3_object.cert_mgmt_zip.bucket
  s3_key           = data.aws_s3_object.cert_mgmt_zip.key
  source_code_hash = data.aws_s3_object.cert_mgmt_zip.etag

  timeout     = var.lambda_timeout
  memory_size = var.lambda_memory_size

  environment {
    variables = {
      "SSM_BASE_PATH" = "/tenantOps${var.environment == "prod" ? "" : "-${var.environment}"}/mcn-lab"
      "S3_BUCKET"     = aws_s3_bucket.cert_bucket.bucket
      "CERT_NAME"     = "mcn-lab-wildcard${var.environment == "prod" ? "" : "-${var.environment}"}"
    }
  }

  tags = local.tags
}

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
        Action   = ["s3:GetObject", "s3:PutObject"],
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
        Resource = [
          "*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "acme_client_lambda_attach" {
  role       = aws_iam_role.acme_client_lambda_role.name
  policy_arn = aws_iam_policy.acme_client_lambda_policy.arn
}

resource "aws_lambda_function" "acme_client_mcn_lambda" {
  function_name    = "tops-acme-client-mcn${var.environment == "prod" ? "" : "-${var.environment}"}"
  role             = aws_iam_role.acme_client_lambda_role.arn
  runtime          = "python3.11"
  handler          = "function.lambda_handler"
  s3_bucket        = data.aws_s3_object.acme_client_zip.bucket
  s3_key           = data.aws_s3_object.acme_client_zip.key
  source_code_hash = data.aws_s3_object.acme_client_zip.etag

  timeout     = var.lambda_timeout
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
