resource "aws_api_gateway_rest_api" "api" {
  name = "crc-counter-api"
}

resource "aws_api_gateway_resource" "resource" {
  path_part   = "counter"
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.api.id
}

resource "aws_api_gateway_method" "method" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.resource.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "apigw-integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.resource.id
  http_method             = aws_api_gateway_method.method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda-get-function.invoke_arn
}

resource "aws_api_gateway_deployment" "apigw-deployment" {
  depends_on = [
    aws_api_gateway_integration.apigw-integration,
  ]

  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = "crc"
}

resource "aws_api_gateway_method_settings" "apigw-settings" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = aws_api_gateway_deployment.apigw-deployment.stage_name
  method_path = "${aws_api_gateway_resource.resource.path_part}/*"

  settings {
    metrics_enabled = true
    logging_level   = "INFO"
  }
}

resource "aws_api_gateway_account" "apigw-attach-iam" {
  cloudwatch_role_arn = aws_iam_role.apigw-role.arn
  depends_on          = [aws_iam_role_policy_attachment.apigw-logs-policy-attach]
}

resource "aws_iam_role" "apigw-role" {
  name = "crc-apigw-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
}

resource "aws_cloudwatch_log_group" "apigw-cloudwatch-log-group" {
  name              = "API-Gateway-Execution-Logs_${aws_api_gateway_rest_api.api.id}/${aws_api_gateway_deployment.apigw-deployment.stage_name}"
  retention_in_days = 14
}

resource "aws_iam_policy" "apigw-logging" {
  name        = "crc-apigw-logging-policy"
  path        = "/"
  description = "IAM policy for logging from apigateway"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams",
        "logs:PutLogEvents",
        "logs:GetLogEvents",
        "logs:FilterLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow",
      "Sid" : "AllowCloudwatchLogging"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "apigw-logs-policy-attach" {
  role       = aws_iam_role.apigw-role.name
  policy_arn = aws_iam_policy.apigw-logging.arn
}
