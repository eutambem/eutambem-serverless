terraform {
  backend "s3" {
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

provider "aws" {
  region = "${var.region}"
}

module "network" {
  source = "./network"
  region = "${var.region}"
}

module "dns" {
  source = "./dns"
}

output "subnets" {
  value = "${module.network.subnets}"
}

output "zone_id" {
  value = "${module.dns.zone_id}"
}

output "certificate_arn" {
  value = "${module.dns.certificate_arn}"
}
