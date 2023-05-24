provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

provider "aws" {
  alias      = "secondary"
  region     = var.aws_region_secondary
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key

  default_tags {
    tags = merge({
      managed_by = "terraform"
      workspace  = terraform.workspace
    }, var.tags)
  }
}
