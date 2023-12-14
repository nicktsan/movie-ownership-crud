output "ConsumerFunction" {
  value       = aws_lambda_function.put_movie_ownership_lambda_function.arn
  description = "ConsumerFunction function name"
}
