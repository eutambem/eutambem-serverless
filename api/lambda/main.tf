variable "api_gw_id" {}
variable "api_gw_parent_id" {}
variable "iam_role" {}

resource "aws_api_gateway_resource" "main" {
  rest_api_id = "${var.api_gw_id}"
  parent_id   = "${var.api_gw_parent_id}"
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "main" {
  rest_api_id   = "${var.api_gw_id}"
  resource_id   = "${aws_api_gateway_resource.main.id}"
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_lambda_function" "main" {
  function_name = "main-${terraform.workspace}"

  s3_bucket = "eutambem-src"
  s3_key    = "v0.0.1/eutambem.zip"

  handler = "index.handler"
  runtime = "nodejs6.10"

  role = "${var.iam_role}"
}

resource "aws_api_gateway_integration" "main" {
  rest_api_id = "${var.api_gw_id}"
  resource_id = "${aws_api_gateway_method.main.resource_id}"
  http_method = "${aws_api_gateway_method.main.http_method}"

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "${aws_lambda_function.main.invoke_arn}"
}

resource "aws_api_gateway_deployment" "eutambem" {
  depends_on = [
    "aws_api_gateway_integration.main",
  ]

  rest_api_id = "${var.api_gw_id}"
  stage_name  = "api"
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.main.arn}"
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_deployment.eutambem.execution_arn}/*/*"
}

output "base_url" {
  value = "${aws_api_gateway_deployment.eutambem.invoke_url}"
}