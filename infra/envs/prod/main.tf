terraform {
  # State bucket is created by ../../bootstrap
  backend "s3" {
    bucket       = "bike-terraform-state-916852432681"
    key          = "infra/terraform.tfstate"
    region       = "eu-west-3"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = "eu-west-3"

  # Refuse to run with credentials for another environment's account.
  allowed_account_ids = ["916852432681"]

  default_tags {
    tags = {
      Project     = "bike"
      Environment = "prod"
    }
  }
}

module "app" {
  source = "../../app"

  # Real user data.
  db_deletion_protection   = true
  db_backup_retention_days = 7
}

output "endpoint_url" {
  value = module.app.endpoint_url
}

output "db_cluster_arn" {
  value = module.app.db_cluster_arn
}

output "db_secret_arn" {
  value = module.app.db_secret_arn
}
