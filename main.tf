terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region= "us-east-1"
}

resource "aws_dynamodb_table" "clima_texas" {
  name         = "TexasWeather"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "fecha"

  attribute {
    name = "fecha"
    type = "S"
  }
}

data "aws_iam_policy_document" "lambda_assume_role" {
  statement{
    actions= ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}



resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role = aws_iam_role.iam_for_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_dynamodb" {
  role = aws_iam_role.iam_for_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"

}

data "archive_file" "lambda_zip" {
  type = "zip"
  source_dir = "${path.module}/lambda_code"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_lambda_function" "texas_weather_lambda" {
  filename = data.archive_file.lambda_zip.output_path
  function_name = "Extract_Texas_Climate"
  role= aws_iam_role.iam_for_lambda.arn
  handler = "lambda_function.lambda_handler"
  runtime = "python3.9"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  timeout = 15
}


resource "aws_cloudwatch_event_rule" "texas_weather_schedule" {
  name                = "texas-weather-hourly"
  description         = "Executes Lamda for Texas weather every hour"
  schedule_expression = "rate(24 hours)"
}


resource "aws_cloudwatch_event_target" "texas_weather_target" {
  rule      = aws_cloudwatch_event_rule.texas_weather_schedule.name
  target_id = "texas-weather-lambda"
  arn       = aws_lambda_function.texas_weather_lambda.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.texas_weather_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.texas_weather_schedule.arn
}