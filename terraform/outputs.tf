output "ci-uploader-access-key" {
  value = aws_iam_access_key.ci_uploader.id
}

output "ci-uploader-secret-key" {
  value     = aws_iam_access_key.ci_uploader.secret
  sensitive = true
}

output "bucket-name" {
  value = aws_s3_bucket.idp_id_broker_search.bucket
}
