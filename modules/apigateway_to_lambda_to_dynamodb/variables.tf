variable "sourceDir" {
  description = "Directory of the source for the lambda"
  type        = string
}

variable "outputPath" {
  description = "Output path of the zip file for the lambda"
  type        = string
}

variable "lambda_name" {
  description = "Name of the lambda function"
  type        = string
}

variable "lambda_role" {
  description = "ARN of the role assigned to the lambda"
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

variable "lambda_layers" {
  description = "List of the lambda layers"
  type        = list(string)
}

variable "environment_variables" {
  description = "Map of environment variables to be used in the lambda function"
  type        = map(string)
}

variable "api_gateway_execution_arn" {
  description = "Execution ARN of api gateway"
  type        = string
}


variable "apigateway_id" {
  description = "Id of the api gateway"
  type        = string
}

variable "apigateway_route_key" {
  description = "route key of the apigateway"
  type        = string
}

variable "api_gateway_execution_arn_suffix" {
  description = "Suffix for the api gateway execution arn"
  type        = string
}
