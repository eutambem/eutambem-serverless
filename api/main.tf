terraform {
  backend "s3" {
    bucket = "terraform.eutambem"
    key    = "state/api/terraform.tfstate"
    region = "sa-east-1"
  }
}

provider "aws" {
  region = "${var.region}"
}

data "terraform_remote_state" "common" {
  workspace = "default"
  backend = "s3"
  config {
    bucket = "terraform.eutambem"
    key    = "state/common/terraform.tfstate"
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

module "lambda" {
  source           = "./lambda"
  api_gw_id        = "${aws_api_gateway_rest_api.eutambem_api.id}"
  api_gw_parent_id = "${aws_api_gateway_rest_api.eutambem_api.root_resource_id}"
}

output "base_url" {
  value = "${module.lambda.base_url}"
}