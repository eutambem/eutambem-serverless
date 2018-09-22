resource "aws_route53_zone" "main" {
  name = "eutambem.org"
}

output "zone_id" {
  value = "${aws_route53_zone.main.zone_id}"
}

