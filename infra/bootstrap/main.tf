# Bootstrap: creates the S3 bucket that stores the state of ../ (the main infra).
# This config itself keeps its (tiny) state locally. If that state is ever lost,
# re-adopt the bucket with:
#   terraform import aws_s3_bucket.tf_state bike-terraform-state-021275983436

terraform {
  required_version = ">= 1.17"

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

resource "aws_s3_bucket" "tf_state" {
  bucket = "bike-terraform-state-021275983436"

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

output "state_bucket" {
  value = aws_s3_bucket.tf_state.bucket
}
