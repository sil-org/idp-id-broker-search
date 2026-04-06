output "ci_uploader_role_arn" {
  description = "AWS Role ARN for CI/CD upload to the S3 bucket"
  value       = aws_iam_role.ci_uploader.arn
}

output "bucket_name_region_1" {
  description = "Bucket name for primary region Lambda function files"
  value       = aws_s3_bucket.idp_id_broker_search.bucket
}

output "bucket_name_region_2" {
  description = "Bucket name for secondary region Lambda function files"
  value       = aws_s3_bucket.idp_id_broker_search_2.bucket
}
