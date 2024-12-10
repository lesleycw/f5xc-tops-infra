output "cert_bucket_name" {
  description = "The name of the S3 bucket"
  value       = aws_s3_bucket.this_bucket.bucket
}

output "cert_bucket_arn" {
  description = "The ARN of the S3 bucket"
  value       = aws_s3_bucket.this_bucket.arn
}