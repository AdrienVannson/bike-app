# Shared by every Lambda: same code bundle, one handler per function.
data "archive_file" "api" {
  type        = "zip"
  source_dir  = "${path.module}/../app/api"
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

resource "aws_cloudwatch_log_group" "api" {
  name              = "/aws/lambda/bike-api"
  retention_in_days = 30
}

resource "aws_lambda_function" "api" {
  function_name = "bike-api"
  role          = aws_iam_role.api.arn

  runtime = "nodejs26.x"
  handler = "src/index.handler"

  timeout     = 29
  memory_size = 256

  filename         = data.archive_file.api.output_path
  source_code_hash = data.archive_file.api.output_base64sha256

  depends_on = [
    aws_cloudwatch_log_group.api,
    aws_iam_role_policy_attachment.api_logs,
  ]
}
