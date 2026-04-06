variable "app_env" {
  type = string
}

variable "app_name" {
  default = "idp-id-broker-search"
}

variable "aws_region" {
  default = "us-east-1"
}

variable "aws_region_secondary" {
  default = "us-west-2"
}

variable "aws_region_new_primary" {
  default = "us-east-2"
}

variable "aws_access_key" {
  default = null
}

variable "aws_secret_key" {
  default = null
}

variable "bucket_policy_principals" {
  description = "AWS accounts, users, or policies that are allowed to read objects in the id-broker-search buckets"
  type        = list(string)
  default     = []
}

variable "github_oidc_provider_arn" {
  description = <<-EOT
    ARN of the OIDC provider for GitHub in AWS IAM, used for GitHub Actions to authenticate to AWS. The provider
    can be created in Terraform using the `aws_iam_openid_connect_provider` resource. Specify the URL as
    "https://token.actions.githubusercontent.com" and the client_id_list as ["sts.amazonaws.com"].
  EOT
  type        = string
}

variable "github_repository" {
  description = <<-EOT
    GitHub repository that should be granted access to the OIDC provider for GitHub. Format should be 'owner/repo'.
  EOT
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
