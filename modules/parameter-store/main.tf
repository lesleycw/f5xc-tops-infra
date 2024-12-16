variable "parameters" {
  description = "Map of parameters to store in Parameter Store. Key is the parameter name, value is an object with 'type', 'value', and optional 'description' and 'tags'."
  type = map(object({
    type        = string
    value       = string
    description = optional(string)
    tags        = optional(map(string))
  }))
}

variable "default_tags" {
  description = "Default tags to apply to all parameters."
  type        = map(string)
  default     = {}
}

resource "aws_ssm_parameter" "parameter" {
  for_each       = var.parameters
  name           = each.key
  type           = each.value.type
  value          = each.value.value
  description    = lookup(each.value, "description", null)
  tags           = merge(var.default_tags, lookup(each.value, "tags", {}))
  tier           = "Standard"
  allowed_pattern = ".*"

  lifecycle {
    create_before_destroy = true
  }
}
