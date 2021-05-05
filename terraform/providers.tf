provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

provider "aws" {
  alias      = "region-2"
  region     = local.aws-region-2
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}
