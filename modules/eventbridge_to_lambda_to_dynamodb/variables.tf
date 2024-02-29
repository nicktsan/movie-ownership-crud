variable "environment" {
  description = "Name of the execution environment"
  type        = string
}

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

variable "dlq_name" {
  description = "Name of the dead letter queue"
  type        = string
}
