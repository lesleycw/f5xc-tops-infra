module "cert_bucket" {
  source      = "./modules/bucket"
  bucket_name = "tops-cert-bucket${var.environment == "prod" ? "" : "-${var.environment}"}"

  tags = local.tags
}

data "aws_s3_object" "cert_mgmt_zip" {
  bucket = module.lambda_bucket.bucket_name
  key    = "cert_mgmt${var.environment == "prod" ? "" : "_${var.environment}"}.zip"
}

module "cert_mgmt_mcn_lambda" {
  source                = "./modules/lambda"
  function_name         = "tops-cert-mgmt-mcn${var.environment == "prod" ? "" : "-${var.environment}"}"
  lambda_role_arn       = aws_iam_role.lambda_execution_role.arn
  s3_bucket             = data.aws_s3_object.cert_mgmt_zip.bucket
  s3_key                = data.aws_s3_object.cert_mgmt_zip.key
  source_code_hash      = data.aws_s3_object.cert_mgmt_zip.etag
  environment_variables = {
    "SSM_BASE_PATH" = "/tenantOps${var.environment == "prod" ? "" : "-${var.environment}"}/mcn-lab",
    "S3_BUCKET"     = module.cert_bucket.bucket_name,
    "CERT_NAME"     = "mcn-lab-wildcard${var.environment == "prod" ? "" : "-${var.environment}"}"
  }
  trigger_type          = "schedule"
  schedule_expression = "cron(0 12 * * ? *)"
  tags                  = local.tags
}

data "aws_s3_object" "acme_client_zip" {
  bucket = module.lambda_bucket.bucket_name
  key    = "acme_client${var.environment == "prod" ? "" : "_${var.environment}"}.zip"
}

module "acme_client_mcn_lambda" {
  source                = "./modules/lambda"
  function_name         = "tops-acme-client-mcn${var.environment == "prod" ? "" : "-${var.environment}"}"
  lambda_role_arn       = aws_iam_role.lambda_execution_role.arn
  s3_bucket             = data.aws_s3_object.acme_client_zip.bucket
  s3_key                = data.aws_s3_object.acme_client_zip.key
  source_code_hash      = data.aws_s3_object.acme_client_zip.etag
  environment_variables = {
    "CERT_NAME"     = "mcn-lab-wildcard${var.environment == "prod" ? "" : "-${var.environment}"}",
    "DOMAIN"        = "mcn-lab${var.environment == "prod" ? "" : "-${var.environment}"}.f5demos.com",
    "S3_BUCKET"     = module.cert_bucket.bucket_name,
    "EMAIL"         = var.acme_email
  }
  trigger_type          = "schedule"
  schedule_expression   = "cron(0 0 * * ? *)"
  tags                  = local.tags
}

output "cert_bucket_name" {
  value = module.cert_bucket.bucket_name
}

output "cert_bucket_arn" {
  value = module.cert_bucket.bucket_arn
}
