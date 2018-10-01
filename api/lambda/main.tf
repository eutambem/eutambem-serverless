variable "api_gw_id" {}
variable "api_gw_parent_id" {}
variable "stage_name" {}
variable "lambda_version" {}

resource "aws_iam_role" "lambda_exec" {
  name = "iam-role-eutambem-lambda-${terraform.workspace}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
    role       = "${aws_iam_role.lambda_exec.name}"
    policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

resource "aws_iam_role_policy_attachment" "lambda_vpc" {
    role       = "${aws_iam_role.lambda_exec.name}"
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

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
  function_name = "eutambem-lambda-${terraform.workspace}"

  s3_bucket     = "eutambem-src"
  s3_key        = "${var.lambda_version}/eutambem.zip"

  handler       = "lambda.handler"
  runtime       = "nodejs8.10"
  role          = "${aws_iam_role.lambda_exec.arn}"
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
  stage_name  = "${var.stage_name}"
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