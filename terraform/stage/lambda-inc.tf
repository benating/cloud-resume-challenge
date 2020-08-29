data "archive_file" "lambda-inc-zip" {
  type        = "zip"
  output_path = "../../lambda-inc.zip"
  source_file = "../../crc/lambda_inc_function.py"
}

resource "aws_lambda_permission" "cloudfront-lambda-inc" {
  provider      = aws.use1
  statement_id  = "AllowExecutionFromCloudfront"
  action        = "lambda:GetFunction"
  function_name = aws_lambda_function.lambda-inc-function-use1.function_name
  principal     = "edgelambda.amazonaws.com"
}

resource "aws_lambda_function" "lambda-inc-function-use1" {
  provider         = aws.use1
  filename         = data.archive_file.lambda-inc-zip.output_path
  source_code_hash = data.archive_file.lambda-inc-zip.output_base64sha256
  function_name    = "crc-lambda-inc"
  role             = aws_iam_role.lambda-inc-role.arn
  handler          = "lambda_inc_function.lambda_handler"
  runtime          = "python3.7"
  publish          = true
}

resource "aws_iam_role" "lambda-inc-role" {
  name = "crc-lambda-inc-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": [
          "lambda.amazonaws.com",
          "edgelambda.amazonaws.com"
        ]
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
}

resource "aws_iam_policy" "inc-dynamodb-policy" {
  name        = "crc-lambda-inc-dynamodb-policy"
  description = "Policy for crc-lambda-inc role to manage crc-counter dynamodb."
  policy      = <<POLICY
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

resource "aws_cloudwatch_log_group" "lambda-inc-cloudwatch-log-group" {
  name              = "/aws/lambda/${aws_lambda_function.lambda-inc-function-use1.function_name}"
  retention_in_days = 14
}

resource "aws_iam_policy" "lambda-inc-logging" {
  name        = "crc-lambda-inc-logging-policy"
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

resource "aws_iam_role_policy_attachment" "lambda-inc-logs-policy-attach" {
  role       = aws_iam_role.lambda-inc-role.name
  policy_arn = aws_iam_policy.lambda-inc-logging.arn
}

resource "aws_iam_role_policy_attachment" "lambda-inc-dynamodb-policy-attach" {
  role       = aws_iam_role.lambda-inc-role.name
  policy_arn = aws_iam_policy.inc-dynamodb-policy.arn
}
