# Shared by every Lambda: same code bundle, one handler per function.
# The bundle must be built first.
data "archive_file" "api" {
  type        = "zip"
  source_dir  = "${path.module}/../../app/api/dist"
  output_path = "${path.module}/build/api.zip"
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# --- API monolith ------------------------------------------------------------

resource "aws_iam_role" "api" {
  name               = "bike-api-lambda"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "api_logs" {
  role       = aws_iam_role.api.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "api_db" {
  statement {
    actions = [
      "rds-data:ExecuteStatement",
      "rds-data:BatchExecuteStatement",
      "rds-data:BeginTransaction",
      "rds-data:CommitTransaction",
      "rds-data:RollbackTransaction",
    ]
    resources = [aws_rds_cluster.db.arn]
  }

  # The Data API reads the DB credentials with the caller's permissions.
  statement {
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [aws_rds_cluster.db.master_user_secret[0].secret_arn]
  }
}

resource "aws_iam_role_policy" "api_db" {
  name   = "database"
  role   = aws_iam_role.api.id
  policy = data.aws_iam_policy_document.api_db.json
}

resource "aws_cloudwatch_log_group" "api" {
  name              = "/aws/lambda/bike-api"
  retention_in_days = 30
}

resource "aws_lambda_function" "api" {
  function_name = "bike-api"
  role          = aws_iam_role.api.arn

  runtime = "nodejs26.x"
  handler = "index.handler"

  timeout     = 29
  memory_size = 256

  filename         = data.archive_file.api.output_path
  source_code_hash = data.archive_file.api.output_base64sha256

  environment {
    variables = {
      DB_CLUSTER_ARN = aws_rds_cluster.db.arn
      DB_SECRET_ARN  = aws_rds_cluster.db.master_user_secret[0].secret_arn
      DB_NAME        = aws_rds_cluster.db.database_name
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.api,
    aws_iam_role_policy_attachment.api_logs,
    aws_iam_role_policy.api_db,
    aws_rds_cluster_instance.db,
  ]
}
