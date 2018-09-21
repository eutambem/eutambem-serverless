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