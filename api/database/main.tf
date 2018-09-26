variable "subnets" { 
  type = "list"
}
data "aws_region" "current" {}

resource "aws_db_subnet_group" "eutambem_db_subnet" {
  name       = "eutambem-db-subnet-${terraform.workspace}"
  subnet_ids = ["${var.subnets}"]
  }

resource "aws_rds_cluster" "eutambem_cluster" {
  cluster_identifier      = "eutambem-cluster-${terraform.workspace}"
  availability_zones      = ["${data.aws_region.current.name}a", "${data.aws_region.current.name}b", "${data.aws_region.current.name}c"]
  database_name           = "eutambem"
  master_username         = "admin"
  master_password         = "zQ4hMn7GX3"
  engine                  = "aurora"
  engine_mode             = "serverless"
  skip_final_snapshot     = true
  db_subnet_group_name    = "${aws_db_subnet_group.eutambem_db_subnet.name}"
  scaling_configuration {
    max_capacity          = 4
  }
}