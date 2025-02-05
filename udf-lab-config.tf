resource "aws_dynamodb_table" "lab_configuration" {
  name         = "tops-lab-config${var.environment == "prod" ? "" : "-${var.environment}"}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "lab_id"

  attribute {
    name = "lab_id"
    type = "S"
  }
}

/*
Individual Lab Configs here
*/

resource "aws_dynamodb_table_item" "lab_cMIxKy" {
  table_name = aws_dynamodb_table.lab_configuration.name
  hash_key   = "lab_id"

  item = jsonencode({
    lab_id          = { S = "cMIxKy" }
    description     = { S = "Lab for testing" }
    ssm_base_path   = { S = "${local.sec_base_path}" }
    sso_type        = { S = "SSO" }
    group_names     = { L = [
      { S = "xc-lab-users" }
    ]}
    namespace_roles = { L = [
      { M = {
        namespace = { S = "system" }
        role      = { S = "f5xc-web-app-scanning-user" }
      }}
    ]}
    pre_lambda      = { S = "arn:aws:lambda:us-west-2:123456789012:function:pre-lambda" }
    post_lambda     = { NULL = true }
  })
}