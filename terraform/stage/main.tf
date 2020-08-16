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

locals {
  env = "stage"
}

resource "aws_s3_bucket" "cv-bucket" {
  bucket = "crc-${local.env}-cv-bucket"
  acl    = "public-read"

  website {
    index_document = "index.html"
  }
}

resource "aws_s3_bucket_object" "cv-upload" {
  bucket = aws_s3_bucket.cv-bucket.id
  key    = "index.html"
  source = "../../src/resources/CV.html"
  etag   = filemd5("../../src/resources/CV.html")
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
