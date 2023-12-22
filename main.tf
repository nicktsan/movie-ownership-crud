#IAM Resource block for Lambda IAM role.
resource "aws_iam_role" "movie_ownership_crud_eventbridge_to_lambda_to_dynamodb_role" {
  name               = var.movie_ownership_crud_eventbridge_to_lambda_to_dynamodb_iam_role
  assume_role_policy = data.template_file.movie_ownership_crud_eventbridge_to_lambda_to_dynamodb_iam_role_template.rendered
}

#attach both IAM Lambda Logging Policy to movie_ownership_crud_eventbridge_to_lambda_to_dynamodb_role
resource "aws_iam_role_policy_attachment" "attach_cloudwatch_iam_policy_for_lambda" {
  role       = aws_iam_role.movie_ownership_crud_eventbridge_to_lambda_to_dynamodb_role.name
  policy_arn = data.aws_iam_policy.lambda_basic_execution_role_policy.arn
}

# lambda to receive message from eventbridge and put data to dynamodb
resource "aws_lambda_function" "put_movie_ownership_lambda_function" {
  filename      = data.archive_file.put_movie_ownership_zip.output_path
  function_name = var.put_movie_ownership_lambda_name
  role          = aws_iam_role.movie_ownership_crud_eventbridge_to_lambda_to_dynamodb_role.arn
  handler       = "index.handler"

  # The filebase64sha256() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the base64sha256() function and the file() function:
  # source_code_hash = "${base64sha256(file("lambda_function_payload.zip"))}"
  source_code_hash = data.archive_file.put_movie_ownership_zip.output_base64sha256
  runtime          = var.lambda_runtime
  layers = [
    aws_lambda_layer_version.lambda_deps_layer.arn,
    aws_lambda_layer_version.lambda_utils_layer.arn
  ]

  environment {
    variables = {
      STRIPE_SECRET         = data.hcp_vault_secrets_secret.stripeSecret.secret_value
      STRIPE_SIGNING_SECRET = data.hcp_vault_secrets_secret.stripeSigningSecret.secret_value
      DYNAMODB_NAME         = var.dynamodb_table
      # STRIPE_EVENT_BUS           = var.event_bus_name
      # stripe_lambda_event_source = var.stripe_lambda_event_source
    }
  }
}

resource "aws_lambda_layer_version" "lambda_deps_layer" {
  layer_name = "movie_ownership_crud_shared_deps"
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
  layer_name = "shared_utils"
  s3_bucket  = aws_s3_bucket.dev_movie_ownership_crud_bucket.id #conflicts with filename
  s3_key     = aws_s3_object.lambda_utils_layer_s3_storage.key  #conflicts with filename
  # filename         = data.archive_file.utils_layer_code_zip.output_path
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
  bucket = "movie-ownership-crud-bucket"

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

#Create a new Event Rule to send eventbridge messages to put_movie_ownership_lambda_function
resource "aws_cloudwatch_event_rule" "put_movie_ownership_eventbridge_event_rule" {
  name           = var.put_movie_ownership_eventbridge_event_rule_name
  event_pattern  = data.template_file.put_movie_ownership_eventbridge_event_rule_pattern_template.rendered
  event_bus_name = data.aws_cloudwatch_event_bus.stripe_webhook_event_bus.arn
}

#Set the put_movie_ownership_lambda_function as a target for the Eventbridge rule
resource "aws_cloudwatch_event_target" "put_movie_ownership_eventbridge_log_group_target" {
  rule           = aws_cloudwatch_event_rule.put_movie_ownership_eventbridge_event_rule.name
  arn            = aws_lambda_function.put_movie_ownership_lambda_function.arn
  event_bus_name = data.aws_cloudwatch_event_bus.stripe_webhook_event_bus.arn
}
# Allow Eventbridge to invoke the lambda
resource "aws_lambda_permission" "allow_cloudwatch" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.put_movie_ownership_lambda_function.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.put_movie_ownership_eventbridge_event_rule.arn
}

# Create a DynamoDB table to store ownership data
resource "aws_dynamodb_table" "movie_ownership_table" {
  name           = var.dynamodb_table
  billing_mode   = "PROVISIONED"
  read_capacity  = 25
  write_capacity = 25
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

# Attach lambda_to_dynamodb_crud_policy to movie_ownership_crud_eventbridge_to_lambda_to_dynamodb_role
resource "aws_iam_role_policy_attachment" "lambda_to_dynamodb_crud_policy_attachment" {
  role       = aws_iam_role.movie_ownership_crud_eventbridge_to_lambda_to_dynamodb_role.name
  policy_arn = aws_iam_policy.lambda_to_dynamodb_crud_policy.arn
}
