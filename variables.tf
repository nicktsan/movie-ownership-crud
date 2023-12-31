variable "environment" {
  description = "Name of the execution environment"
  type        = string
}

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

variable "stripe_checkout_session_completed_event_type" {
  description = "Event type of the stripe webhook event being sent to the PUT movie_ownership_crud lambda"
  type        = string
}

variable "put_movie_ownership_eventbridge_event_rule_name" {
  description = "Name of put_movie_ownership_eventbridge_event_rule"
  type        = string
}

variable "dynamodb_table" {
  description = "Name of the dynamodb table for movie ownership crud app"
  type        = string
}

variable "lambda_to_dynamodb_crud_policy_name" {
  description = "Name of the policy for lambdas to perform crud operations on dynamodb tables"
  type        = string
}

variable "movie_ownership_crud_schedule_group_name" {
  description = "Name of the schedule group for the movie ownership crud app in eventbridge"
  type        = string
}

variable "delete_movie_ownership_lambda_name" {
  description = "Name of the lambda function to delete movie ownership"
  type        = string
}

variable "EventBridgeSchedulerRoleName" {
  description = "Name of the Eventbridge Scheduler role"
  type        = string
}

variable "EventBridgeSchedulerPolicyName" {
  description = "Name of the IAM policy that allows eventbridge to invoke lambdas"
  type        = string
}

variable "eventbridge_scheduler_delete_movie_ownership_dlq_name" {
  description = "Name of the DLQ that receives failed messages from the eventbridge scheduler"
  type        = string
}

variable "delete_movie_ownership_eventbridge_event_rule_name" {
  description = "Name of the Event rule to send messages to delete_movie_ownership lambda function"
  type        = string
}

variable "delete_movie_ownership_event_type" {
  description = "Event type for the delete movie ownership event rule pattern rule"
  type        = string
}

variable "stripe_eventbridge_scheduler_event_source" {
  description = "Event source for the delete movie ownership event rule pattern rule"
  type        = string
}
