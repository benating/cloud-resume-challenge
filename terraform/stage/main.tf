terraform {
  backend "s3" {
    bucket = "crc-tfstate-bucket"
    key    = "stage/terraform.tfstate"
    region = "eu-west-2"

    dynamodb_table = "crc-tfstate-locks"
    encrypt        = true
  }
}

provider "aws" {
  version = "~> 3.0"
  region  = "eu-west-2"
}

provider "aws" {
  version = "~> 3.0"
  region  = "us-east-1"
  alias   = "use1"
}

locals {
  env              = "stage"
  s3_origin_id     = "CVBucketOrigin"
  root_domain_name = "bernardting.com"
  cv_domain_name   = "cv.${local.root_domain_name}"
}

resource "aws_s3_bucket" "cv-bucket" {
  bucket = "crc-${local.env}-cv-bucket"
  acl    = "public-read"

  website {
    index_document = "index.html"
  }
}

resource "aws_s3_bucket_object" "cv-upload" {
  bucket       = aws_s3_bucket.cv-bucket.id
  key          = "index.html"
  source       = "../../src/main/resources/CV.html"
  content_type = "text/html"
  etag         = filemd5("../../src/main/resources/CV.html")
}

resource "aws_s3_bucket_policy" "cv-bucket-policy" {
  bucket = aws_s3_bucket.cv-bucket.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "CvBucketPolicy",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": [
          "s3:GetObject"
      ],
      "Resource": "arn:aws:s3:::crc-${local.env}-cv-bucket/*"
    }
  ]
}
POLICY
}

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

resource "aws_cloudfront_distribution" "www-distribution" {
  origin {
    custom_origin_config {
      http_port              = "80"
      https_port             = "443"
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }

    domain_name = aws_s3_bucket.cv-bucket.website_endpoint
    origin_id   = local.s3_origin_id
  }

  enabled             = true
  default_root_object = "index.html"

  default_cache_behavior {
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = local.s3_origin_id
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  aliases = [local.cv_domain_name]

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate_validation.cert-validation.certificate_arn
    ssl_support_method  = "sni-only"
  }
}
