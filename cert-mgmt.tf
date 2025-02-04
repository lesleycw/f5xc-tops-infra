/*
S3 Bucket to store all generated certificates
*/

module "cert_bucket" {
  source      = "./modules/bucket"
  bucket_name = "tops-cert-bucket${var.environment == "prod" ? "" : "-${var.environment}"}"

  tags = local.tags
}

output "cert_bucket_name" {
  value = module.cert_bucket.bucket_name
}

output "cert_bucket_arn" {
  value = module.cert_bucket.bucket_arn
}

/*
Lambda function to manage certificates in tenants
*/

data "aws_s3_object" "cert_mgmt_zip" {
  bucket = module.lambda_bucket.bucket_name
  key    = "cert_mgmt${var.environment == "prod" ? "" : "_${var.environment}"}.zip"
}

resource "aws_iam_policy" "cert_mgmt_lambda_policy" {
  name        = "cert_mgmt_lambda_policy${var.environment == "prod" ? "" : "-${var.environment}"}"
  description = "IAM Policy for the Cert Management Lambda"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["logs:CreateLogStream", "logs:PutLogEvents"],
        Resource = "arn:aws:logs:*:*:log-group:/aws/lambda/tops-cert-mgmt*"
      },
      {
        Effect   = "Allow",
        Action   = ["s3:GetObject", "s3:PutObject"],
        Resource = "arn:aws:s3:::${module.cert_bucket.bucket_name}/*"
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

module "cert_mgmt_mcn_lambda" {
  count                 = length(data.aws_s3_object.cert_mgmt_zip.id) > 0 ? 1 : 0
  source                = "./modules/lambda"
  function_name         = "tops-cert-mgmt-mcn${var.environment == "prod" ? "" : "-${var.environment}"}"
  lambda_role_arn       = aws_iam_role.lambda_execution_role.arn
  lambda_policy_arn     = aws_iam_policy.cert_mgmt_lambda_policy.arn
  s3_bucket             = data.aws_s3_object.cert_mgmt_zip.bucket
  s3_key                = data.aws_s3_object.cert_mgmt_zip.key
  source_code_hash      = data.aws_s3_object.cert_mgmt_zip.etag
  environment_variables = {
    "SSM_BASE_PATH" = "/tenantOps${var.environment == "prod" ? "" : "-${var.environment}"}/mcn-lab",
    "S3_BUCKET"     = module.cert_bucket.bucket_name,
    "CERT_NAME"     = "mcn-lab-wildcard${var.environment == "prod" ? "" : "-${var.environment}"}"
  }
  schedule_expression   = "cron(0 12 * * ? *)"
  tags                  = local.tags
}

/*
Lambda function to act as ACME client to create/update certs
*/

data "aws_s3_object" "acme_client_zip" {
  bucket = module.lambda_bucket.bucket_name
  key    = "acme_client${var.environment == "prod" ? "" : "_${var.environment}"}.zip"
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
        Resource = "arn:aws:s3:::${module.cert_bucket.bucket_name}/*"
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

module "acme_client_mcn_lambda" {
  count                 = length(data.aws_s3_object.acme_client_zip.id) > 0 ? 1 : 0
  source                = "./modules/lambda"
  function_name         = "tops-acme-client-mcn${var.environment == "prod" ? "" : "-${var.environment}"}"
  lambda_role_arn       = aws_iam_role.lambda_execution_role.arn
  lambda_policy_arn     = aws_iam_policy.acme_client_lambda_policy.arn
  s3_bucket             = data.aws_s3_object.acme_client_zip.bucket
  s3_key                = data.aws_s3_object.acme_client_zip.key
  source_code_hash      = data.aws_s3_object.acme_client_zip.etag
  environment_variables = {
    "CERT_NAME"     = "mcn-lab-wildcard${var.environment == "prod" ? "" : "-${var.environment}"}",
    "DOMAIN"        = "mcn-lab${var.environment == "prod" ? "" : "-${var.environment}"}.f5demos.com",
    "S3_BUCKET"     = module.cert_bucket.bucket_name,
    "EMAIL"         = var.acme_email
  }
  schedule_expression   = "cron(0 0 * * ? *)" # Set up the scheduled trigger
  tags                  = local.tags
}