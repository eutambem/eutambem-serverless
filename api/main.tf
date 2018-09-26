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

resource "aws_api_gateway_rest_api" "eutambem_api" {
  name        = "eutambem-api-${terraform.workspace}"
  description = "API for Eu Tambem - ${terraform.workspace}"
}

resource "aws_api_gateway_domain_name" "api_domain_name" {
  domain_name = "api-${terraform.workspace}.eutambem.org"

  certificate_arn = "${data.terraform_remote_state.common.certificate_arn}"
}

locals {
  stage_name = "v1"
}

resource "aws_api_gateway_base_path_mapping" "domain_mapping" {
  api_id      = "${aws_api_gateway_rest_api.eutambem_api.id}"
  domain_name = "${aws_api_gateway_domain_name.api_domain_name.domain_name}"
  stage_name  = "${local.stage_name}"
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
  stage_name       = "${local.stage_name}"
  subnets          = ["${data.terraform_remote_state.common.subnets}"]
}

resource "aws_db_subnet_group" "eutambem_db_subnet" {
  name       = "eutambem-db-subnet-${terraform.workspace}"
  subnet_ids = ["${data.terraform_remote_state.common.subnets}"]
  }

resource "aws_rds_cluster" "eutambem_cluster" {
  cluster_identifier      = "eutambem-cluster-${terraform.workspace}"
  availability_zones      = ["${var.region}a", "${var.region}b", "${var.region}c"]
  database_name           = "eutambem"
  master_username         = "admin"
  master_password         = "zQ4hMn7GX3"
  engine                  = "aurora"
  engine_mode             = "serverless"
  skip_final_snapshot     = true
  db_subnet_group_name    = "${aws_db_subnet_group.eutambem_db_subnet.name}"
}

output "base_url" {
  value = "${module.lambda.base_url}"
}