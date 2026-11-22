terraform {
  # State bucket is created by ../../bootstrap
  backend "s3" {
    bucket       = "bike-terraform-state-453899702980"
    key          = "infra/terraform.tfstate"
    region       = "eu-west-3"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = "eu-west-3"

  # Refuse to run with credentials for another environment's account.
  allowed_account_ids = ["453899702980"]

  default_tags {
    tags = {
      Project     = "bike"
      Environment = "dev"
    }
  }
}

module "app" {
  source = "../../app"

  # Disposable data: the database can be destroyed freely.
  db_deletion_protection   = false
  db_backup_retention_days = 1
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
