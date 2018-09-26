variable "region" {}

resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"

  tags {
    Name = "eutambem"
  }
}

resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags {
    Name = "eutambem-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.default.id}"
  }

  tags {
    Name = "eutambem-public-route-table"
  }
}

resource "aws_subnet" "subnet_a" {
  vpc_id                  = "${aws_vpc.vpc.id}"
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "${var.region}a"

  tags {
    Name = "eutambem-subnet-a"
  }
}

resource "aws_subnet" "subnet_b" {
  vpc_id                  = "${aws_vpc.vpc.id}"
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "${var.region}b"

  tags {
    Name = "eutambem-subnet-b"
  }
}

resource "aws_subnet" "subnet_c" {
  vpc_id                  = "${aws_vpc.vpc.id}"
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "${var.region}c"

  tags {
    Name = "eutambem-subnet-c"
  }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = "${aws_subnet.subnet_a.id}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = "${aws_subnet.subnet_b.id}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_route_table_association" "public_c" {
  subnet_id      = "${aws_subnet.subnet_c.id}"
  route_table_id = "${aws_route_table.public.id}"
}

output "subnets" {
  value = ["${aws_subnet.subnet_a.id}", "${aws_subnet.subnet_b.id}", "${aws_subnet.subnet_c.id}"]
}