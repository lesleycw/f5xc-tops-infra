resource "aws_iam_role" "lambda_execution_role" {
  name = "tops-lambda-execution-role${var.environment == "prod" ? "" : "-${var.environment}"}"

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

resource "aws_iam_policy" "lambda_execution_policy" {
  name = "tops-lambda-execution-policy${var.environment == "prod" ? "" : "-${var.environment}"}"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = "ecr:GetAuthorizationToken",
        Resource = "*"
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
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ],
        Resource = [
          module.cert_bucket.bucket_arn,
          "${module.cert_bucket.bucket_arn}/*"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "route53:ChangeResourceRecordSets",
          "route53:GetChange",
          "route53:ListResourceRecordSets",
          "route53:ListHostedZones"
        ],
        Resource = [
          "arn:aws:route53:::hostedzone/${var.zone_id}"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_execution_policy.arn
}

module "lambda_bucket" {
  source      = "./modules/bucket"
  bucket_name = "tops-lambda-bucket${var.environment == "prod" ? "" : "-${var.environment}"}"

  tags = local.tags
}

output "lambda_bucket_name" {
  value = module.lambda_bucket.bucket_name
}

output "lambda_bucket_arn" {
  value = module.lambda_bucket.bucket_arn
}