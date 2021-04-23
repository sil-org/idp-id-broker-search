
terraform {
  required_version = ">= 0.14"
  required_providers {
    aws = {
      version = "~> 2.70"
      source  = "hashicorp/aws"
    }
    null = {
      version = "~> 3.0"
      source  = "hashicorp/null"
    }
    template = {
      version = "~> 2.2"
      source  = "hashicorp/template"
    }
  }
}
