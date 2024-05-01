provider "aws" {
  region = var.region
}

data "archive_file" "greet_lambda" {
    type          = "zip"
    source_file   = "greet_lambda.py"
    output_path   = "greet_lambda.zip"
}

resource "aws_iam_role" "role_lambda" {
  name = "role_lambda"

  assume_role_policy = <<EOF
  {
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : "sts:AssumeRole",
        "Effect" : "Allow",
        "Sid"    : "",
        "Principal" : {
          "Service" : "lambda.amazonaws.com"
        }
      }
    ]
  }
  EOF
}

resource "aws_iam_policy" "lambda_log" {
  name        = "lambda_log"
  path        = "/"
  policy = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Effect": "Allow",
        "Resource": "arn:aws:logs:*:*:*"
      }
    ]
  }
  EOF
}

resource "aws_iam_role_policy_attachment" "lambda_log" {
  role       = aws_iam_role.role_lambda.name
  policy_arn = aws_iam_policy.lambda_log.arn
}

resource "aws_lambda_function" "greet_lambda" {
  filename         = "greet_lambda.zip"
  function_name    = "greet_lambda"
  handler          = "greet_lambda.lambda_handler"
  source_code_hash = data.archive_file.greet_lambda.output_base64sha256
  role             = aws_iam_role.role_lambda.arn
  runtime          = "python3.8"

  depends_on = [aws_iam_role_policy_attachment.lambda_log]

  environment {
    variables = {
      greeting = "Hello Udacity"
    }
  }
}

