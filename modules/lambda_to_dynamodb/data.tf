# Setup for put_movie_ownership lambda
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = var.sourceDir
  output_path = var.outputPath
}

# template file to use for the PUT event rule pattern.
data "template_file" "eventbridge_event_rule_pattern_template" {
  template = file(var.eventbridge_event_rule_pattern_template_file_path)

  vars = {
    eventSource = var.stripe_lambda_event_source
    eventType   = var.event_type
  }
}

# Eventbridge Event Bus that the PUT lambda will be sourcing events from
data "aws_cloudwatch_event_bus" "stripe_webhook_event_bus" {
  name = var.event_bus_name
}

# Template file for the dlq policy
data "template_file" "dlq_policy_template" {
  template = file("./modules/lambda_to_dynamodb/template/dlq_policy.tpl")
  vars = {
    dlqArn       = aws_sqs_queue.dlq.arn
    eventRuleArn = aws_cloudwatch_event_rule.eventbridge_event_rule.arn
  }
}
