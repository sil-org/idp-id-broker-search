output "ci_uploader_access_key" {
  value = aws_iam_access_key.ci_uploader.id
}

output "ci_uploader_secret_key" {
  value     = aws_iam_access_key.ci_uploader.secret
  sensitive = true
}

output "bucket_name_region_1" {
  value = aws_s3_bucket.idp_id_broker_search.bucket
}

output "bucket_name_region_2" {
  value = aws_s3_bucket.idp_id_broker_search_2.bucket
}
