
// Create S3 bucket for uploading binary
resource "aws_s3_bucket" "idp_id_broker_search" {
  bucket        = "${var.app_name}-${var.aws_region}"
  force_destroy = false

  tags = {
    app_name = var.app_name
    app_env  = var.app_env
  }
}

moved {
  from = aws_s3_bucket.idp-id-broker-search
  to   = aws_s3_bucket.idp_id_broker_search
}

resource "aws_s3_bucket_versioning" "idp_id_broker_search" {
  bucket = aws_s3_bucket.idp_id_broker_search.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "idp_id_broker_search" {
  bucket = aws_s3_bucket.idp_id_broker_search.id
  rule {
    id     = "delete-old-objects"
    status = "Enabled"

    # empty filter applies to all objects in the bucket
    filter {}

    noncurrent_version_expiration {
      noncurrent_days           = 1
      newer_noncurrent_versions = 1
    }
  }
}

moved {
  from = aws_s3_bucket_versioning.idp-id-broker-search
  to   = aws_s3_bucket_versioning.idp_id_broker_search
}

resource "aws_s3_bucket_ownership_controls" "idp_id_broker_search" {
  bucket = aws_s3_bucket.idp_id_broker_search.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
  depends_on = [aws_s3_bucket_public_access_block.idp_id_broker_search]
}


resource "aws_s3_bucket_public_access_block" "idp_id_broker_search" {
  bucket                  = aws_s3_bucket.idp_id_broker_search.id
  block_public_acls       = true
  block_public_policy     = false
  ignore_public_acls      = true
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "idp_id_broker_search" {
  bucket = aws_s3_bucket.idp_id_broker_search.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "LimitedAccess"
        Effect = "Allow"
        Principal = {
          AWS = var.bucket_policy_principals
        }
        Action   = "s3:GetObject"
        Resource = "arn:aws:s3:::${aws_s3_bucket.idp_id_broker_search.bucket}/*"
      },
      {
        Sid    = "PublicAccessChecksum"
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Action   = "s3:GetObject"
        Resource = "arn:aws:s3:::${aws_s3_bucket.idp_id_broker_search.bucket}/*.sum"
      },
    ]
  })
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
  provider = aws.secondary

  bucket = aws_s3_bucket.idp_id_broker_search_2.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
  depends_on = [aws_s3_bucket_public_access_block.idp_id_broker_search_2]
}


resource "aws_s3_bucket_public_access_block" "idp_id_broker_search_2" {
  provider = aws.secondary

  bucket                  = aws_s3_bucket.idp_id_broker_search_2.id
  block_public_acls       = true
  block_public_policy     = false
  ignore_public_acls      = true
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "idp_id_broker_search_2" {
  provider = aws.secondary

  bucket = aws_s3_bucket.idp_id_broker_search_2.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "LimitedAccess"
        Effect = "Allow"
        Principal = {
          AWS = var.bucket_policy_principals
        }
        Action   = "s3:GetObject"
        Resource = "arn:aws:s3:::${aws_s3_bucket.idp_id_broker_search_2.bucket}/*"
      },
      {
        Sid    = "PublicAccessChecksum"
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Action   = "s3:GetObject"
        Resource = "arn:aws:s3:::${aws_s3_bucket.idp_id_broker_search_2.bucket}/*.sum"
      },
    ]
  })
}

/*
 * AWS Role for CI/CD upload to the S3 bucket
 */

resource "aws_iam_role" "ci_uploader" {
  name = "${var.app_name}-uploader"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "GitHub"
      Effect = "Allow"
      Action = "sts:AssumeRoleWithWebIdentity"
      Principal = {
        Federated = var.github_oidc_provider_arn
      }
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" : "sts.amazonaws.com"
        },
        StringLike = {
          "token.actions.githubusercontent.com:sub" : "repo:${var.github_repository}:*"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "ci_uploader" {
  name = "S3-Access"
  role = aws_iam_role.ci_uploader.name

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl",
        ]
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.idp_id_broker_search.bucket}/*",
          "arn:aws:s3:::${aws_s3_bucket.idp_id_broker_search_2.bucket}/*",
        ]
      }
    ]
  })
}
