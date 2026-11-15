terraform {
  required_version = ">= 1.17"

  # State bucket is created by ./bootstrap
  backend "s3" {
    bucket       = "bike-terraform-state-021275983436"
    key          = "infra/terraform.tfstate"
    region       = "eu-west-3"
    encrypt      = true
    use_lockfile = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.8"
    }
  }
}

provider "aws" {
  region = "eu-west-3"
}
