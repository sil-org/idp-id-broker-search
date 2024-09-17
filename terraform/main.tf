
// Create S3 bucket for uploading binary
resource "aws_s3_bucket" "idp_id_broker_search" {
  bucket        = "${var.app_name}-${var.aws_region}"
  force_destroy = true

  tags = {
    app_name = var.app_name
    app_env  = var.app_env
  }
}

moved {
  from = aws_s3_bucket.idp-id-broker-search
  to   = aws_s3_bucket.idp_id_broker_search
}

resource "aws_s3_bucket_acl" "idp_id_broker_search" {
  bucket     = aws_s3_bucket.idp_id_broker_search.id
  acl        = "public-read"
  depends_on = [aws_s3_bucket_ownership_controls.idp_id_broker_search]
}

moved {
  from = aws_s3_bucket_acl.idp-id-broker-search
  to   = aws_s3_bucket_acl.idp_id_broker_search
}

resource "aws_s3_bucket_versioning" "idp_id_broker_search" {
  bucket = aws_s3_bucket.idp_id_broker_search.id
  versioning_configuration {
    status = "Enabled"
  }
}

moved {
  from = aws_s3_bucket_versioning.idp-id-broker-search
  to   = aws_s3_bucket_versioning.idp_id_broker_search
}

resource "aws_s3_bucket_ownership_controls" "idp_id_broker_search" {
  provider = aws.new_primary

  bucket = aws_s3_bucket.idp_id_broker_search.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
  depends_on = [aws_s3_bucket_public_access_block.idp_id_broker_search]
}


resource "aws_s3_bucket_public_access_block" "idp_id_broker_search" {
  provider = aws.new_primary

  bucket                  = aws_s3_bucket.idp_id_broker_search.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

// Create a second S3 bucket for uploading binary to a different region (crude form of replication)
resource "aws_s3_bucket" "idp_id_broker_search_2" {
  provider      = aws.secondary
  bucket        = "${var.app_name}-${var.aws_region_secondary}"
  force_destroy = true

  tags = {
    app_name = var.app_name
    app_env  = var.app_env
  }
}

moved {
  from = aws_s3_bucket.idp-id-broker-search-2
  to   = aws_s3_bucket.idp_id_broker_search_2
}

resource "aws_s3_bucket_acl" "idp_id_broker_search_2" {
  provider   = aws.secondary
  bucket     = aws_s3_bucket.idp_id_broker_search_2.id
  acl        = "public-read"
  depends_on = [aws_s3_bucket_ownership_controls.idp_id_broker_search_2]
}

moved {
  from = aws_s3_bucket_acl.idp-id-broker-search-2
  to   = aws_s3_bucket_acl.idp_id_broker_search_2
}

resource "aws_s3_bucket_versioning" "idp_id_broker_search_2" {
  provider = aws.secondary
  bucket   = aws_s3_bucket.idp_id_broker_search_2.id
  versioning_configuration {
    status = "Enabled"
  }
}

moved {
  from = aws_s3_bucket_versioning.idp-id-broker-search-2
  to   = aws_s3_bucket_versioning.idp_id_broker_search_2
}

resource "aws_s3_bucket_ownership_controls" "idp_id_broker_search_2" {
  provider = aws.new_primary

  bucket = aws_s3_bucket.idp_id_broker_search_2.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
  depends_on = [aws_s3_bucket_public_access_block.idp_id_broker_search_2]
}


resource "aws_s3_bucket_public_access_block" "idp_id_broker_search_2" {
  provider = aws.new_primary

  bucket                  = aws_s3_bucket.idp_id_broker_search_2.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}


// Create a third S3 bucket for migration of primary region to us-east_2
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

  bucket     = aws_s3_bucket.idp_id_broker_search_3.id
  acl        = "public-read"
  depends_on = [aws_s3_bucket_ownership_controls.idp_id_broker_search_3]
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

resource "aws_iam_user" "ci_uploader" {
  name = "${var.app_name}-uploader"
}

moved {
  from = aws_iam_user.ci-uploader
  to   = aws_iam_user.ci_uploader
}

resource "aws_iam_access_key" "ci_uploader" {
  user = aws_iam_user.ci_uploader.name
}

moved {
  from = aws_iam_access_key.ci-uploader
  to   = aws_iam_access_key.ci_uploader
}

data "template_file" "ci_uploader" {
  template = file("${path.module}/ci-bucket-policy.json")

  vars = {
    bucket_name  = aws_s3_bucket.idp_id_broker_search.bucket
    bucket2_name = aws_s3_bucket.idp_id_broker_search_2.bucket
    bucket3_name = aws_s3_bucket.idp_id_broker_search_3.bucket
  }
}

resource "aws_iam_user_policy" "ci_uploader" {
  name = "S3-Access"
  user = aws_iam_user.ci_uploader.name

  policy = data.template_file.ci_uploader.rendered
}

moved {
  from = aws_iam_user_policy.ci-uploader
  to   = aws_iam_user_policy.ci_uploader
}
