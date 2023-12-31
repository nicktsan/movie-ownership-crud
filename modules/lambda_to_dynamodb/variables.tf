variable "lambda_name" {
  description = "Name of the lambda function"
  type        = string
}

variable "lambda_handler" {
  description = "Name of the handler function for the lambda"
  type        = string
}

variable "lambda_runtime" {
  description = "Runtime of the lambda functions"
  type        = string
}

variable "lambda_role" {
  description = "ARN of the role assigned to the lambda"
  type        = string
}

variable "lambda_layers" {
  description = "List of the lambda layers"
  type        = list(string)
}

# variable "stripe_secret_key" {
#   description = "Key of the stripe secret stored in hcp vault secrets"
#   type        = string
#   sensitive   = true
# }

# variable "stripe_webhook_signing_secret" {
#   description = "Key of the stripe webhook signing secret stored in hcp vault secrets"
#   type        = string
#   sensitive   = true
# }

# variable "dynamodb_table" {
#   description = "Name of the dynamodb table for movie ownership crud app"
#   type        = string
# }

variable "eventbridge_event_rule_name" {
  description = "Name of eventbridge_event_rule"
  type        = string
}

variable "eventbridge_event_rule_pattern_template_file_path" {
  description = "Path of the file for the template file to be used for Eventbridge event rule pattern."
  type        = string
}

variable "stripe_lambda_event_source" {
  description = "source of the eventbridge event"
  type        = string
}

variable "event_type" {
  description = "Event type of the stripe webhook event being sent to the lambda"
  type        = string
}

variable "event_bus_name" {
  description = "Name of the event bus for sending eventbridge messages to lambda"
  type        = string
}

# variable "hcp_vault_secrets_app_name" {
#   description = "Name of the app from where hcp vault will access its secrets from"
#   type        = string
# }

variable "sourceDir" {
  description = "Directory of the source for the lambda"
  type        = string
}

variable "outputPath" {
  description = "Output path of the zip file for the lambda"
  type        = string
}

variable "environment_variables" {
  description = "Map of environment variables to be used in the lambda function"
  type        = map(string)
}
