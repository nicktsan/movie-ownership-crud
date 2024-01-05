# lambda to receive message from API Gateway and perform CRUD operations to dynamodb
resource "aws_lambda_function" "lambda_function" {
  filename      = data.archive_file.lambda_zip.output_path
  function_name = var.lambda_name
  role          = var.lambda_role
  handler       = var.lambda_handler

  # The filebase64sha256() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the base64sha256() function and the file() function:
  # source_code_hash = "${base64sha256(file("lambda_function_payload.zip"))}"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime          = var.lambda_runtime
  layers           = var.lambda_layers

  environment {
    variables = var.environment_variables
  }
}

# Allow API Gateway to invoke the lambda
resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_function.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = var.api_gateway_execution_arn //"${aws_apigatewayv2_api.http_lambda.execution_arn}/*/*"
}
