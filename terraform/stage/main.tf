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
  region  = local.region
}

provider "aws" {
  version = "~> 3.0"
  region  = "us-east-1"
  alias   = "use1"
}

locals {
  account_id       = "973533177904"
  region           = "eu-west-2"
  lambda_zip_path  = "../../lambda.zip"
  env              = "stage"
  s3_origin_id     = "CVBucketOrigin"
  root_domain_name = "bernardting.com"
  cv_domain_name   = "cv.${local.root_domain_name}"
}
