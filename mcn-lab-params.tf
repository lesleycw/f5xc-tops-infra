locals {
  param_base_path = "/tenantOps-${var.environment}/mcn-lab"
}

module "parameter_store" {
  source = "./modules/parameter-store"

  parameters = {
    "${local.param_base_path}/tenant-url" = {
      type        = "SecureString"
      value       = "https://f5-xc-lab.console.ves.volterra.io"
    }
  }
  default_tags    = local.tags
}