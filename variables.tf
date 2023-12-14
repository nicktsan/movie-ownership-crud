variable "stripe_secret_key" {
  description = "Key of the stripe secret stored in hcp vault secrets"
  type        = string
  sensitive   = true
}

variable "stripe_webhook_signing_secret" {
  description = "Key of the stripe webhook signing secret stored in hcp vault secrets"
  type        = string
  sensitive   = true
}

variable "region" {
  description = "Region of the app"
  type        = string
}

variable "put_movie_ownership_lambda_name" {
  description = "Name of the put_movie_ownership_lambda_function"
  type        = string
}

variable "lambda_runtime" {
  description = "Runtime of the lambda functions"
  type        = string
}

variable "detail_type" {
  description = "detail-type of eventbridge event"
  type        = string
}

variable "stripe_lambda_event_source" {
  description = "source of the eventbridge event"
  type        = string
}

variable "deps_layer_storage_key" {
  description = "Key of the S3 Object that will store deps lambda layer"
  type        = string
}

variable "utils_layer_storage_key" {
  description = "Key of the S3 object that will store utils lambda layer"
  type        = string
}

variable "movie_ownership_crud_eventbridge_to_lambda_to_dynamodb_iam_role" {
  description = "Name of the IAM role for the PUT movie_ownership_crud lambda"
  type        = string
}

variable "event_bus_name" {
  description = "Name of the event bus for sending eventbridge messages to lambda"
  type        = string
}

variable "stripe_webhook_event_type" {
  description = "Event type of the stripe webhook event being sent to the PUT movie_ownership_crud lambda"
  type        = string
}

variable "put_movie_ownership_eventbridge_event_rule_name" {
  description = "Name of put_movie_ownership_eventbridge_event_rule"
  type        = string
}
