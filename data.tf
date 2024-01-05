# initialize the current caller to get their account number information
data "aws_caller_identity" "current" {}

# data to grab the stripe secret from hcp vault secrets
data "hcp_vault_secrets_secret" "stripeSecret" {
  app_name    = var.hcp_vault_secrets_app_name
  secret_name = var.stripe_secret_key
}

# data to grab the stripe webhook signing secret from hcp vault secrets
data "hcp_vault_secrets_secret" "stripeSigningSecret" {
  app_name    = var.hcp_vault_secrets_app_name
  secret_name = var.stripe_webhook_signing_secret
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
data "template_file" "lambda_to_dynamodb_iam_role_template" {
  template = file("./template/lambda_to_dynamodb_iam_role.tpl")
}

# Provides write permissions to CloudWatch Logs.
data "aws_iam_policy" "lambda_basic_execution_role_policy" {
  name = "AWSLambdaBasicExecutionRole"
}

#template file for the policy to allow lambdas to perform CRUD operations on dynamodb tables
data "template_file" "lambda_to_dynamodb_crud_policy_template" {
  template = file("./template/lambda_to_dynamodb_crud_policy.tpl")

  vars = {
    dynamodb_table = var.dynamodb_table
  }
}
