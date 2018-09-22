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

resource "aws_api_gateway_domain_name" "api_domain_name" {
  domain_name = "api-${terraform.workspace}.eutambem.org"

  certificate_arn = "${data.terraform_remote_state.common.certificate_arn}"
}

resource "aws_route53_record" "api_record" {
  zone_id = "${data.terraform_remote_state.common.zone_id}"
  name = "${aws_api_gateway_domain_name.api_domain_name.domain_name}"
  type = "A"

  alias {
    name                   = "${aws_api_gateway_domain_name.api_domain_name.cloudfront_domain_name}"
    zone_id                = "${aws_api_gateway_domain_name.api_domain_name.cloudfront_zone_id}"
    evaluate_target_health = true
  }
}

module "lambda" {
  source           = "./lambda"
  api_gw_id        = "${aws_api_gateway_rest_api.eutambem_api.id}"
  api_gw_parent_id = "${aws_api_gateway_rest_api.eutambem_api.root_resource_id}"
}

output "base_url" {
  value = "${module.lambda.base_url}"
}