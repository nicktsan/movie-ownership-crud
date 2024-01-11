output "PutFunction" {
  value       = module.put_movie_ownership_lambda.ConsumerFunction
  description = "PutFunction function arn"
}

output "api_endpoint" {
  value       = aws_apigatewayv2_api.http_lambda.api_endpoint
  description = "Test API endpoint with this address"
}
