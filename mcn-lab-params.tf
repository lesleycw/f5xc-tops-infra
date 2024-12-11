locals {
  param_base_path = "/tenantOps-${var.environment}/mcn-lab"
}

module "parameter_store" {
  source = "./modules/parameter-store"

  parameters = {
    "${local.param_base_path}/tenant-url" = {
      type        = "String"
      value       = "https://f5-xc-lab.console.ves.volterra.io"
    }
    "${local.param_base_path}/token-name" = {
      type        = "String"
      value       = "tenant-ops-mrflfitl"
    }
    "${local.param_base_path}/token-value" = {
      type        = "SecureString"
      value       = var.mcn_lab_token
    }
  }
  default_tags    = local.tags
}