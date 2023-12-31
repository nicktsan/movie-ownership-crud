output "PutFunction" {
  value       = module.put_movie_ownership_lambda.ConsumerFunction
  description = "PutFunction function arn"
}
