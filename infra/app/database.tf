# Aurora Serverless v2 (PostgreSQL), reached only through the RDS Data API.

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_db_subnet_group" "db" {
  name       = "bike-db"
  subnet_ids = data.aws_subnets.default.ids
}

# Intentionally no ingress rules: the Data API does not need any.
resource "aws_security_group" "db" {
  name        = "bike-db"
  description = "Aurora cluster, no direct access (Data API only)"
  vpc_id      = data.aws_vpc.default.id
}

resource "aws_rds_cluster" "db" {
  cluster_identifier = "bike-db"

  engine         = "aurora-postgresql"
  engine_mode    = "provisioned"
  engine_version = "18.6"

  database_name               = "bike"
  master_username             = "bike_admin"
  manage_master_user_password = true # RDS generates and stores it in Secrets Manager

  enable_http_endpoint = true # RDS Data API

  apply_immediately = true

  db_subnet_group_name   = aws_db_subnet_group.db.name
  vpc_security_group_ids = [aws_security_group.db.id]

  storage_encrypted = true

  serverlessv2_scaling_configuration {
    min_capacity             = 0
    max_capacity             = 1
    seconds_until_auto_pause = 900
  }

  backup_retention_period   = 7
  deletion_protection       = true
  skip_final_snapshot       = false
  final_snapshot_identifier = "bike-db-final"
  copy_tags_to_snapshot     = true

  lifecycle {
    ignore_changes = [engine_version]
  }
}

resource "aws_rds_cluster_instance" "db" {
  identifier         = "bike-db-1"
  cluster_identifier = aws_rds_cluster.db.id

  instance_class = "db.serverless"
  engine         = aws_rds_cluster.db.engine
}

output "db_cluster_arn" {
  value = aws_rds_cluster.db.arn
}

output "db_secret_arn" {
  value = aws_rds_cluster.db.master_user_secret[0].secret_arn
}
