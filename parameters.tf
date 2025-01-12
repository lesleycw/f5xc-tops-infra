variable "mcn_lab_token" {
  description = "Access token for the MCN Lab Tenant"
  type        = string
  sensitive   = true
}

variable "app_lab_token" {
  description = "Access token for the App Lab Tenant"
  type        = string
  sensitive   = true
}

variable "sec_lab_token" {
  description = "Access token for the Sec Lab Tenant"
  type        = string
  sensitive   = true
}

locals {
  app_base_path = "/tenantOps-${var.environment}/app-lab"
  mcn_base_path = "/tenantOps-${var.environment}/mcn-lab"
  sec_base_path = "/tenantOps-${var.environment}/sec-lab"
}

module "app_lab_parameters" {
  source = "./modules/parameter-store"

  parameters = {
    "${local.app_base_path}/tenant-url" = {
      type        = "String"
      value       = "https://f5-xc-lab-app.console.ves.volterra.io"
    }
    "${local.app_base_path}/token-name" = {
      type        = "String"
      value       = "tenant-ops-abkdibjd"
    }
    "${local.app_base_path}/token-value" = {
      type        = "SecureString"
      value       = var.app_lab_token
    }
  }
  default_tags    = local.tags
}

module "mcn_lab_parameters" {
  source = "./modules/parameter-store"

  parameters = {
    "${local.mcn_base_path}/tenant-url" = {
      type        = "String"
      value       = "https://f5-xc-lab-mcn.console.ves.volterra.io"
    }
    "${local.mcn_base_path}/token-name" = {
      type        = "String"
      value       = "tenant-ops-mrflfitl"
    }
    "${local.mcn_base_path}/token-value" = {
      type        = "SecureString"
      value       = var.mcn_lab_token
    }
  }
  default_tags    = local.tags
}

module "sec_lab_parameters" {
  source = "./modules/parameter-store"

  parameters = {
    "${local.sec_base_path}/tenant-url" = {
      type        = "String"
      value       = "https://f5-xc-lab-sec.console.ves.volterra.io"
    }
    "${local.sec_base_path}/token-name" = {
      type        = "String"
      value       = "tenant-ops-rcsodtbj"
    }
    "${local.sec_base_path}/token-value" = {
      type        = "SecureString"
      value       = var.sec_lab_token
    }
  }
  default_tags    = local.tags
}