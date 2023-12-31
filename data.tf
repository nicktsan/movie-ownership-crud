# initialize the current caller to get their account number information
data "aws_caller_identity" "current" {}

# data to grab the stripe secret from hcp vault secrets
data "hcp_vault_secrets_secret" "stripeSecret" {
  app_name    = "movie-app"
  secret_name = var.stripe_secret_key
}

# data to grab the stripe webhook signing secret from hcp vault secrets
data "hcp_vault_secrets_secret" "stripeSigningSecret" {
  app_name    = "movie-app"
  secret_name = var.stripe_webhook_signing_secret
}

# Setup for put_movie_ownership lambda
data "archive_file" "put_movie_ownership_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/dist/handlers/put_movie_ownership/"
  output_path = "${path.module}/lambda/dist/put_movie_ownership.zip"
}

# Setup for util lambda layer
data "archive_file" "utils_layer_code_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/dist/layers/util-layer/"
  output_path = "${path.module}/lambda/dist/utils.zip"
}

# Setup for dependencies lambda layer
data "archive_file" "deps_layer_code_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/dist/layers/deps-layer/"
  output_path = "${path.module}/lambda/dist/deps.zip"
}

# template file to use for lambda
data "template_file" "movie_ownership_crud_eventbridge_to_lambda_to_dynamodb_iam_role_template" {
  template = file("./template/movie_ownership_crud_eventbridge_to_lambda_to_dynamodb_iam_role.tpl")
}

# Provides write permissions to CloudWatch Logs.
data "aws_iam_policy" "lambda_basic_execution_role_policy" {
  name = "AWSLambdaBasicExecutionRole"
}

# template file to use for the PUT event rule pattern.
data "template_file" "put_movie_ownership_eventbridge_event_rule_pattern_template" {
  template = file("./template/put_movie_ownership_eventbridge_event_rule_pattern.tpl")

  vars = {
    stripeLambdaEventSource                 = var.stripe_lambda_event_source
    stripeCheckoutSessionCompletedEventType = var.stripe_checkout_session_completed_event_type
  }
}

# Eventbridge Event Bus that the PUT and DELETE lambdas will be sourcing events from
data "aws_cloudwatch_event_bus" "stripe_webhook_event_bus" {
  name = var.event_bus_name
}

#template file for the policy to allow lambdas to perform CRUD operations on dynamodb tables
data "template_file" "lambda_to_dynamodb_crud_policy_template" {
  template = file("./template/lambda_to_dynamodb_crud_policy.tpl")

  vars = {
    dynamodb_table = var.dynamodb_table
  }
}

# Setup for delete_movie_ownership lambda
data "archive_file" "delete_movie_ownership_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/dist/handlers/delete_movie_ownership/"
  output_path = "${path.module}/lambda/dist/delete_movie_ownership.zip"
}

# Template file for the Eventbridge Scheduler role
data "template_file" "EventBridgeSchedulerRole_template" {
  template = file("./template/EventBridgeSchedulerRole.tpl")
}

# Template file for the IAM Policy to allow eventbridge to invoke lambda
data "template_file" "EventBridgeSchedulerPolicy_template" {
  template = file("./template/EventBridgeSchedulerPolicy.tpl")
}

# Template file to for the delete movie ownership event rule pattern
data "template_file" "delete_movie_ownership_eventbridge_event_rule_pattern_template" {
  template = file("./template/delete_movie_ownership_eventbridge_event_rule_pattern.tpl")

  vars = {
    StripeEventbridgeSchedulerEventSource = var.stripe_eventbridge_scheduler_event_source
    DeleteMovieOwnershipEventType         = var.delete_movie_ownership_event_type
  }
}
