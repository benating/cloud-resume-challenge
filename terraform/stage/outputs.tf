output "apigw-base-url" {
  value = aws_api_gateway_deployment.apigw-deployment.invoke_url
}

output "cloudfront-base-url" {
  value = aws_cloudfront_distribution.www-distribution.domain_name
}
