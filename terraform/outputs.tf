output "ci_uploader_access_key" {
  description = "AWS Access Key ID for CI/CD pipeline"
  value       = aws_iam_access_key.ci_uploader.id
}

output "ci_uploader_secret_key" {
  description = "AWS Access Key Secret for CI/CD pipeline"
  value       = aws_iam_access_key.ci_uploader.secret
  sensitive   = true
}

output "bucket_name_region_1" {
  description = "Bucket name for primary region Lambda function files"
  value       = aws_s3_bucket.idp_id_broker_search.bucket
}

output "bucket_name_region_2" {
  description = "Bucket name for secondary region Lambda function files"
  value       = aws_s3_bucket.idp_id_broker_search_2.bucket
}
