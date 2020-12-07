provider "aws" {
  version    = "~> 2.70"
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

provider "template" {
  version = "~> 2.2"
}

provider "null" {
  version = "~> 3.0"
}
