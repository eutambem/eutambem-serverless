terraform {
  backend "s3" {
    bucket = "terraform.eutambem"
    key    = "terraform/terraform.tfstate"
    region = "sa-east-1"
  }
}

provider "aws" {
  region = "${var.region}"
}

data "terraform_remote_state" "network" {
  workspace = "default"
  backend = "s3"
  config {
    bucket = "terraform.eutambem"
    key    = "state/network/terraform.tfstate"
    region = "sa-east-1"
  }
}

variable "region" {
  default = "us-east-1"
}

variable "availability_zone" {
  default = "us-east-1a"
}

resource "aws_api_gateway_rest_api" "eutambem_api" {
  name        = "eutambem-api-${terraform.workspace}"
  description = "API for Eu Tambem - ${terraform.workspace}"
}

resource "aws_iam_role" "lambda_exec" {
  name = "iam-role-lambda-${terraform.workspace}"

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

module "lambda" {
  source           = "./lambda"
  api_gw_id        = "${aws_api_gateway_rest_api.eutambem_api.id}"
  api_gw_parent_id = "${aws_api_gateway_rest_api.eutambem_api.root_resource_id}"
  iam_role         = "${aws_iam_role.lambda_exec.arn}"
}

output "base_url" {
  value = "${module.lambda.base_url}"
}