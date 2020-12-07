output "ci-uploader-access-key" {
  value = aws_iam_access_key.ci-uploader.id
}

output "ci-uploader-secret-key" {
  value = aws_iam_access_key.ci-uploader.secret
}

output "bucket-name" {
  value = aws_s3_bucket.idp-id-broker-search.bucket
}
