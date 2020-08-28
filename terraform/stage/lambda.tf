data "archive_file" "lambda-zip" {
  type        = "zip"
  output_path = local.lambda_zip_path
  source_dir  = "../../crc"
}

resource "aws_lambda_permission" "apigw-lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda-function.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "arn:aws:execute-api:${local.region}:${local.account_id}:${aws_api_gateway_rest_api.api.id}/*/*/${aws_api_gateway_resource.resource.path_part}"
}

resource "aws_lambda_function" "lambda-function" {
  filename         = local.lambda_zip_path
  source_code_hash = data.archive_file.lambda-zip.output_base64sha256
  function_name    = "crc-lambda"
  role             = aws_iam_role.lambda-role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.7"
}

resource "aws_iam_role" "lambda-role" {
  name = "crc-lambda-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
}

resource "aws_iam_policy" "dynamodb-policy" {
  name        = "crc-lambda-dynamodb-policy"
  description = "Policy for crc-lambda role to manage crc-counter dynamodb."
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "dynamodb:DescribeTable",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
        "dynamodb:GetItem"
      ],
      "Resource": "${aws_dynamodb_table.counter-db.arn}",
      "Effect": "Allow",
      "Sid": "AllowReadAndWriteToDynamoDb"
    }
  ]
}
POLICY
}

resource "aws_cloudwatch_log_group" "lambda-cloudwatch-log-group" {
  name              = "/aws/lambda/${aws_lambda_function.lambda-function.function_name}"
  retention_in_days = 14
}

resource "aws_iam_policy" "lambda-logging" {
  name        = "crc-lambda-logging-policy"
  path        = "/"
  description = "IAM policy for logging from a lambda"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow",
      "Sid" : "AllowCloudwatchLogging"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "lambda-logs-policy-attach" {
  role       = aws_iam_role.lambda-role.name
  policy_arn = aws_iam_policy.lambda-logging.arn
}

resource "aws_iam_role_policy_attachment" "lambda-dynamodb-policy-attach" {
  role       = aws_iam_role.lambda-role.name
  policy_arn = aws_iam_policy.dynamodb-policy.arn
}
