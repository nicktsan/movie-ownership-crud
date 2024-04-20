#IAM Resource block for Lambda IAM role.
resource "aws_iam_role" "lambda_to_dynamodb_role" {
  name               = var.lambda_to_dynamodb_iam_role
  assume_role_policy = data.template_file.lambda_to_dynamodb_iam_role_template.rendered
}

#attach both IAM Lambda Logging Policy to lambda_to_dynamodb_role
resource "aws_iam_role_policy_attachment" "attach_cloudwatch_iam_policy_for_lambda" {
  role       = aws_iam_role.lambda_to_dynamodb_role.name
  policy_arn = data.aws_iam_policy.lambda_basic_execution_role_policy.arn
}

resource "aws_lambda_layer_version" "lambda_deps_layer" {
  layer_name = var.movie_ownership_lambda_deps_layer_name
  s3_bucket  = aws_s3_bucket.dev_movie_ownership_crud_bucket.id #conflicts with filename
  s3_key     = aws_s3_object.lambda_deps_layer_s3_storage.key   #conflicts with filename
  // If using s3_bucket or s3_key, do not use filename, as they conflict
  # filename         = data.archive_file.deps_layer_code_zip.output_path
  source_code_hash = data.archive_file.deps_layer_code_zip.output_base64sha256

  compatible_runtimes = [var.lambda_runtime]
  depends_on = [
    aws_s3_object.lambda_deps_layer_s3_storage,
  ]
}
# Create an s3 resource for storing the utils_layer
resource "aws_lambda_layer_version" "lambda_utils_layer" {
  layer_name       = var.lambda_utils_layer_name
  s3_bucket        = aws_s3_bucket.dev_movie_ownership_crud_bucket.id #conflicts with filename
  s3_key           = aws_s3_object.lambda_utils_layer_s3_storage.key  #conflicts with filename
  source_code_hash = data.archive_file.utils_layer_code_zip.output_base64sha256

  compatible_runtimes = [var.lambda_runtime]
  depends_on = [
    aws_s3_object.lambda_utils_layer_s3_storage,
  ]
}

#create an s3 resource for storing the deps layer
resource "aws_s3_object" "lambda_deps_layer_s3_storage" {
  bucket = aws_s3_bucket.dev_movie_ownership_crud_bucket.id
  key    = var.deps_layer_storage_key
  source = data.archive_file.deps_layer_code_zip.output_path

  # The filemd5() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the md5() function and the file() function:
  # etag = "${md5(file("path/to/file"))}"
  etag = data.archive_file.deps_layer_code_zip.output_base64sha256
  depends_on = [
    data.archive_file.deps_layer_code_zip,
  ]
}

# create an s3 object for storing the utils layer
resource "aws_s3_object" "lambda_utils_layer_s3_storage" {
  bucket = aws_s3_bucket.dev_movie_ownership_crud_bucket.id
  key    = var.utils_layer_storage_key
  source = data.archive_file.utils_layer_code_zip.output_path

  # The filemd5() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the md5() function and the file() function:
  # etag = "${md5(file("path/to/file"))}"
  etag = data.archive_file.utils_layer_code_zip.output_base64sha256
  depends_on = [
    data.archive_file.utils_layer_code_zip,
  ]
}

resource "aws_s3_bucket" "dev_movie_ownership_crud_bucket" {
  bucket = "movie-ownership-crud-bucket2"

  tags = {
    Name        = "My movie_ownership_crud dev bucket"
    Environment = "dev"
  }
}
//applies an s3 bucket acl resource to s3_backend
resource "aws_s3_bucket_acl" "s3_acl" {
  bucket     = aws_s3_bucket.dev_movie_ownership_crud_bucket.id
  acl        = "private"
  depends_on = [aws_s3_bucket_ownership_controls.dev_movie_ownership_crud_bucket_acl_ownership]
}
# Resource to avoid error "AccessControlListNotSupported: The bucket does not allow ACLs"
resource "aws_s3_bucket_ownership_controls" "dev_movie_ownership_crud_bucket_acl_ownership" {
  bucket = aws_s3_bucket.dev_movie_ownership_crud_bucket.id
  rule {
    object_ownership = "ObjectWriter"
  }
}

# Create a DynamoDB table to store ownership data
resource "aws_dynamodb_table" "movie_ownership_table" {
  name           = var.dynamodb_table
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "customer" #partition key
  range_key      = "title"    #sort key

  attribute {
    name = "customer"
    type = "S"
  }

  attribute {
    name = "title"
    type = "S"
  }

}

# Create a policy to allow lambdas to perform crud operations on dynamodb tables
resource "aws_iam_policy" "lambda_to_dynamodb_crud_policy" {
  name        = var.lambda_to_dynamodb_crud_policy_name
  path        = "/"
  description = "IAM policy to allow lambdas to perform crud operations on dynamodb tables"
  policy      = data.template_file.lambda_to_dynamodb_crud_policy_template.rendered
  lifecycle {
    create_before_destroy = true
  }
}

# Attach lambda_to_dynamodb_crud_policy to lambda_to_dynamodb_role
resource "aws_iam_role_policy_attachment" "lambda_to_dynamodb_crud_policy_attachment" {
  role       = aws_iam_role.lambda_to_dynamodb_role.name
  policy_arn = aws_iam_policy.lambda_to_dynamodb_crud_policy.arn
}

########################PUT MOVIE OWNERSHIP##########################
# Module for lambda to recieve messages from eventbridge and put data to dynamodb
module "put_movie_ownership_lambda" {
  source         = "./modules/eventbridge_to_lambda_to_dynamodb"
  environment    = var.environment
  lambda_name    = var.put_movie_ownership_lambda_name
  lambda_handler = var.lambda_handler
  lambda_runtime = var.lambda_runtime
  lambda_layers = [
    aws_lambda_layer_version.lambda_deps_layer.arn,
    aws_lambda_layer_version.lambda_utils_layer.arn
  ]
  eventbridge_event_rule_name                       = var.put_movie_ownership_eventbridge_event_rule_name
  eventbridge_event_rule_pattern_template_file_path = "./template/eventbridge_event_rule_pattern.tpl"
  stripe_lambda_event_source                        = var.stripe_lambda_event_source
  event_type                                        = var.stripe_checkout_session_completed_event_type
  event_bus_name                                    = var.event_bus_name
  lambda_role                                       = aws_iam_role.lambda_to_dynamodb_role.arn
  sourceDir                                         = "${path.module}/lambda/dist/handlers/put_movie_ownership/"
  outputPath                                        = "${path.module}/lambda/dist/put_movie_ownership.zip"
  environment_variables = {
    STRIPE_SECRET         = data.hcp_vault_secrets_secret.stripeSecret.secret_value
    STRIPE_SIGNING_SECRET = data.hcp_vault_secrets_secret.stripeSigningSecret.secret_value
    DYNAMODB_NAME         = var.dynamodb_table
  }
  dlq_name = var.put_movie_ownership_dlq_name
}
########################SELECT ALL MOVIE OWNERSHIP##########################
# Module for lambda to receive messages from api gateway and select all movies owned by user
#Test with https://keoncigqy7.execute-api.us-east-1.amazonaws.com/movieownership
module "select_all_movie_ownership" {
  source         = "./modules/apigateway_to_lambda_to_dynamodb"
  sourceDir      = "${path.module}/lambda/dist/handlers/select_all_movie_ownership/"
  outputPath     = "${path.module}/lambda/dist/select_all_movie_ownership.zip"
  lambda_name    = var.select_all_movie_ownership_name
  lambda_role    = aws_iam_role.lambda_to_dynamodb_role.arn
  lambda_handler = var.lambda_handler
  lambda_runtime = var.lambda_runtime
  lambda_layers = [
    aws_lambda_layer_version.lambda_deps_layer.arn,
    aws_lambda_layer_version.lambda_utils_layer.arn
  ]
  environment_variables = {
    STRIPE_SECRET         = data.hcp_vault_secrets_secret.stripeSecret.secret_value
    STRIPE_SIGNING_SECRET = data.hcp_vault_secrets_secret.stripeSigningSecret.secret_value
    DYNAMODB_NAME         = var.dynamodb_table
    ROUTE_KEY             = var.get_all_apigateway_route_key
  }
  api_gateway_execution_arn        = aws_apigatewayv2_api.http_lambda.execution_arn
  apigateway_id                    = aws_apigatewayv2_api.http_lambda.id
  apigateway_route_key             = var.get_all_apigateway_route_key
  api_gateway_execution_arn_suffix = var.get_all_api_gateway_execution_arn_suffix
}

########################SELECT SPECIFIC MOVIE OWNERSHIP##########################
# Module for lambda to receive messages from api gateway and select specific movies owned by user
#Test with https://keoncigqy7.execute-api.us-east-1.amazonaws.com/movieownership/{title}
module "select_specific_movie_ownership" {
  source         = "./modules/apigateway_to_lambda_to_dynamodb"
  sourceDir      = "${path.module}/lambda/dist/handlers/select_specific_movie_ownership/"
  outputPath     = "${path.module}/lambda/dist/select_specific_movie_ownership.zip"
  lambda_name    = var.select_specific_movie_ownership_name
  lambda_role    = aws_iam_role.lambda_to_dynamodb_role.arn
  lambda_handler = var.lambda_handler
  lambda_runtime = var.lambda_runtime
  lambda_layers = [
    aws_lambda_layer_version.lambda_deps_layer.arn,
    aws_lambda_layer_version.lambda_utils_layer.arn
  ]
  environment_variables = {
    STRIPE_SECRET         = data.hcp_vault_secrets_secret.stripeSecret.secret_value
    STRIPE_SIGNING_SECRET = data.hcp_vault_secrets_secret.stripeSigningSecret.secret_value
    DYNAMODB_NAME         = var.dynamodb_table
    ROUTE_KEY             = var.get_specific_apigateway_route_key
  }
  api_gateway_execution_arn        = aws_apigatewayv2_api.http_lambda.execution_arn
  apigateway_id                    = aws_apigatewayv2_api.http_lambda.id
  apigateway_route_key             = var.get_specific_apigateway_route_key
  api_gateway_execution_arn_suffix = var.get_specific_api_gateway_execution_arn_suffix
}

#========================================================================
// API Gateway section
#========================================================================

resource "aws_apigatewayv2_api" "http_lambda" {
  name          = var.apigw_name
  protocol_type = var.api_protocol_type
}

resource "aws_apigatewayv2_stage" "default" { //todo https://awstip.com/building-a-serverless-crud-api-on-aws-with-terraform-and-python-13187146b4e8
  api_id = aws_apigatewayv2_api.http_lambda.id

  name        = var.apigateway_stage_name
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw.arn

    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      authorizererror         = "$context.authorizer.error",
      errormessage            = "$context.error.message",
      errormessageString      = "$context.error.messageString",
      errorresponseType       = "$context.error.responseType",
      integrationerror        = "$context.integration.error",
      integrationErrorMessage = "$context.integrationErrorMessage"
      }
    )
  }
  depends_on = [aws_cloudwatch_log_group.api_gw]
}

resource "aws_cloudwatch_log_group" "api_gw" {
  name = "/aws/api_gw/${var.apigw_name}"

  # retention_in_days = var.apigw_log_retention
}

# TODO implement alerts for DLQs
