
// Create S3 bucket for uploading binary
resource "aws_s3_bucket" "idp-id-broker-search" {
  bucket        = "${var.app_name}-${var.aws_region}"
  force_destroy = true

  tags = {
    app_name = var.app_name
    app_env  = var.app_env
  }
}

resource "aws_s3_bucket_acl" "idp-id-broker-search" {
  bucket = aws_s3_bucket.idp-id-broker-search.id
  acl    = "public-read"
}

resource "aws_s3_bucket_versioning" "idp-id-broker-search" {
  bucket = aws_s3_bucket.idp-id-broker-search.id
  versioning_configuration {
    status = "Enabled"
  }
}

// Create a second S3 bucket for uploading binary to a different region (crude form of replication)
resource "aws_s3_bucket" "idp-id-broker-search-2" {
  provider      = aws.secondary
  bucket        = "${var.app_name}-${var.aws_region_secondary}"
  force_destroy = true

  tags = {
    app_name = var.app_name
    app_env  = var.app_env
  }
}

resource "aws_s3_bucket_acl" "idp-id-broker-search-2" {
  provider = aws.secondary
  bucket   = aws_s3_bucket.idp-id-broker-search-2.id
  acl      = "public-read"
}

resource "aws_s3_bucket_versioning" "idp-id-broker-search-2" {
  provider = aws.secondary
  bucket   = aws_s3_bucket.idp-id-broker-search-2.id
  versioning_configuration {
    status = "Enabled"
  }
}


// Create a third S3 bucket for migration of primary region to us-east-2
resource "aws_s3_bucket" "idp_id_broker_search_3" {
  provider      = aws.new_primary
  bucket        = "${var.app_name}-${var.aws_region_new_primary}"
  force_destroy = true

  tags = {
    app_name = var.app_name
    app_env  = var.app_env
  }
}

resource "aws_s3_bucket_acl" "idp_id_broker_search_3" {
  provider = aws.new_primary

  bucket = aws_s3_bucket.idp_id_broker_search_3.id
  acl    = "public-read"
}

resource "aws_s3_bucket_versioning" "idp_id_broker_search_3" {
  provider = aws.new_primary

  bucket = aws_s3_bucket.idp_id_broker_search_3.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_ownership_controls" "idp_id_broker_search_3" {
  provider = aws.new_primary

  bucket = aws_s3_bucket.idp_id_broker_search_3.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
  depends_on = [aws_s3_bucket_public_access_block.idp_id_broker_search_3]
}


resource "aws_s3_bucket_public_access_block" "idp_id_broker_search_3" {
  provider = aws.new_primary

  bucket                  = aws_s3_bucket.idp_id_broker_search_3.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_iam_user" "ci-uploader" {
  name = "${var.app_name}-uploader"
}

resource "aws_iam_access_key" "ci-uploader" {
  user = aws_iam_user.ci-uploader.name
}

data "template_file" "ci-uploader" {
  template = file("${path.module}/ci-bucket-policy.json")

  vars = {
    bucket_name  = aws_s3_bucket.idp-id-broker-search.bucket
    bucket2_name = aws_s3_bucket.idp-id-broker-search-2.bucket
    bucket3_name = aws_s3_bucket.idp_id_broker_search_3.bucket
  }
}

resource "aws_iam_user_policy" "ci-uploader" {
  name = "S3-Access"
  user = aws_iam_user.ci-uploader.name

  policy = data.template_file.ci-uploader.rendered
}
