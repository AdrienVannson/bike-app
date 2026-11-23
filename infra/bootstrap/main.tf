# Bootstrap: creates the S3 bucket that stores the state of ../envs/<env>,
# in whichever account the credentials point to. In the test account, it also
# creates the role used by CI to deploy. Run it once per environment:
#   pnpm tf:bootstrap:dev init
#   pnpm tf:bootstrap:dev apply
#
# This config keeps its state locally, in state/<env>.tfstate.
# If that state is ever lost, re-adopt the existing bucket before applying:
#   pnpm tf:bootstrap:<env> init
#   pnpm tf:bootstrap:<env> import aws_s3_bucket.tf_state bike-terraform-state-<account-id>

terraform {
  required_version = ">= 1.17"

  backend "local" {}

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "eu-west-3"
}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "tf_state" {
  bucket = "bike-terraform-state-${data.aws_caller_identity.current.account_id}"

  lifecycle {
    prevent_destroy = true
  }
}

# Every state write becomes a new object version, so any past state can be restored.
resource "aws_s3_bucket_versioning" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# --- CI deployments (test account only) --------------------------------------

locals {
  account_ids = {
    dev  = "453899702980"
    test = "125035824962"
    prod = "916852432681"
  }

  ci_deploy_enabled = data.aws_caller_identity.current.account_id == local.account_ids.test
}

resource "aws_iam_openid_connect_provider" "github" {
  count = local.ci_deploy_enabled ? 1 : 0

  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}

data "aws_iam_policy_document" "ci_deploy_assume_role" {
  count = local.ci_deploy_enabled ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github[0].arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Only jobs that declare `environment: test`.
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:AdrienVannson@11526087/bike-app@1439940665:environment:test"]
    }
  }
}

resource "aws_iam_role" "ci_deploy" {
  count = local.ci_deploy_enabled ? 1 : 0

  name               = "bike-ci-deploy"
  assume_role_policy = data.aws_iam_policy_document.ci_deploy_assume_role[0].json
}

resource "aws_iam_role_policy_attachment" "ci_deploy_admin" {
  count = local.ci_deploy_enabled ? 1 : 0

  role       = aws_iam_role.ci_deploy[0].name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

output "state_bucket" {
  value = aws_s3_bucket.tf_state.bucket
}
