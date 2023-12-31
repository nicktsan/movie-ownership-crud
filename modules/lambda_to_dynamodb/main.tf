# lambda to receive message from eventbridge and perform CRUD operations to dynamodb
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

#Create a new Event Rule to send eventbridge messages to lambda_function
resource "aws_cloudwatch_event_rule" "eventbridge_event_rule" {
  name           = var.eventbridge_event_rule_name
  event_pattern  = data.template_file.eventbridge_event_rule_pattern_template.rendered
  event_bus_name = data.aws_cloudwatch_event_bus.stripe_webhook_event_bus.arn
}

#Set the lambda_function as a target for the Eventbridge rule
resource "aws_cloudwatch_event_target" "eventbridge_target" {
  rule           = aws_cloudwatch_event_rule.eventbridge_event_rule.name
  arn            = aws_lambda_function.lambda_function.arn
  event_bus_name = data.aws_cloudwatch_event_bus.stripe_webhook_event_bus.arn
}
# Allow Eventbridge to invoke the lambda
resource "aws_lambda_permission" "allow_cloudwatch" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_function.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.eventbridge_event_rule.arn
}
