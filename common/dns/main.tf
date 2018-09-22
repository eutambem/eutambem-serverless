resource "aws_route53_zone" "main" {
  name = "eutambem.org"
}

resource "aws_acm_certificate" "cert" {
  domain_name       = "*.eutambem.org"
  validation_method = "DNS"
}

resource "aws_route53_record" "cert_cname" {
  zone_id = "${aws_route53_zone.main.zone_id}"
  name    = "${aws_acm_certificate.cert.domain_validation_options.0.resource_record_name}"
  type    = "${aws_acm_certificate.cert.domain_validation_options.0.resource_record_type}"
  ttl     = "300"
  records = ["${aws_acm_certificate.cert.domain_validation_options.0.resource_record_value}"]
}

output "zone_id" {
  value = "${aws_route53_zone.main.zone_id}"
}

output "certificate_arn" {
  value = "${aws_acm_certificate.cert.arn}"
}
