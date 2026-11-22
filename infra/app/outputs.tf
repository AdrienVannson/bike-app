output "endpoint_url" {
  value = aws_apigatewayv2_api.api_gateway.api_endpoint
}

output "db_cluster_arn" {
  value = aws_rds_cluster.db.arn
}

output "db_secret_arn" {
  value = aws_rds_cluster.db.master_user_secret[0].secret_arn
}
