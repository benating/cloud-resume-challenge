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
