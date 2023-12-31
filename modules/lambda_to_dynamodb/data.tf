# Setup for put_movie_ownership lambda
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = var.sourceDir
  output_path = var.outputPath
}

# data to grab the stripe secret from hcp vault secrets
# data "hcp_vault_secrets_secret" "stripeSecret" {
#   app_name    = var.hcp_vault_secrets_app_name
#   secret_name = var.stripe_secret_key
# }

# # data to grab the stripe webhook signing secret from hcp vault secrets
# data "hcp_vault_secrets_secret" "stripeSigningSecret" {
#   app_name    = var.hcp_vault_secrets_app_name
#   secret_name = var.stripe_webhook_signing_secret
# }

# template file to use for the PUT event rule pattern.
data "template_file" "eventbridge_event_rule_pattern_template" {
  template = file(var.eventbridge_event_rule_pattern_template_file_path)

  vars = {
    eventSource = var.stripe_lambda_event_source
    eventType   = var.event_type
  }
}

# Eventbridge Event Bus that the PUT and DELETE lambdas will be sourcing events from
data "aws_cloudwatch_event_bus" "stripe_webhook_event_bus" {
  name = var.event_bus_name
}
