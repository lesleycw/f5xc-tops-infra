variable "repository_name" {
  description = "The name of the ECR repository"
  type        = string
}

variable "tags" {
  description = "Tags to apply to the ECR repository"
  type        = map(string)
  default     = {}
}

variable "force_delete" {
  description = "Force delete the ECR repository even if it contains images"
  type        = bool
  default     = false
}

resource "aws_ecr_repository" "ecr" {
  name = var.repository_name
  tags = var.tags
  force_delete = var.force_delete
}

output "repository_url" {
  description = "The URL of the ECR repository"
  value       = aws_ecr_repository.ecr.repository_url
}

output "repository_arn" {
  description = "The ARN of the ECR repository"
  value       = aws_ecr_repository.ecr.arn
}