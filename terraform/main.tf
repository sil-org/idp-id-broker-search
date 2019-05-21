// Create S3 bucket for uploading binary
resource "aws_s3_bucket" "idp-id-broker-search" {
  bucket        = "${var.app_name}-${var.aws_region}"
  acl           = "public-read"
  force_destroy = true

  versioning {
    enabled = true
  }

  tags {
    app_name = "${var.app_name}"
    app_env  = "${var.app_env}"
  }
}

resource "aws_iam_user" "ci-uploader" {
  name = "${var.app_name}-uploader"
}

resource "aws_iam_access_key" "ci-uploader" {
  user = "${aws_iam_user.ci-uploader.name}"
}

data "template_file" "ci-uploader" {
  template = "${file("${path.module}/ci-bucket-policy.json")}"

  vars {
    bucket_name = "${aws_s3_bucket.idp-id-broker-search.bucket}"
  }
}

resource "aws_iam_user_policy" "ci-uploader" {
  name = "S3-Access"
  user = "${aws_iam_user.ci-uploader.name}"

  policy = "${data.template_file.ci-uploader.rendered}"
}
