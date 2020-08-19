resource "aws_acm_certificate" "cert" {
  provider                  = aws.use1
  domain_name               = "*.${local.root_domain_name}"
  subject_alternative_names = ["${local.root_domain_name}"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_route53_zone" "zone" {
  name         = local.root_domain_name
  private_zone = false
}

resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = local.cv_domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.www-distribution.domain_name
    zone_id                = aws_cloudfront_distribution.www-distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "dns-validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.zone.zone_id
}

resource "aws_acm_certificate_validation" "cert-validation" {
  provider        = aws.use1
  certificate_arn = aws_acm_certificate.cert.arn
}
