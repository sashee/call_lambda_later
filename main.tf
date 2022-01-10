provider "aws" {
}

# Lambda function

resource "random_id" "id" {
  byte_length = 8
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "/tmp/${random_id.id.hex}-lambda.zip"
  source {
    content  = <<EOF
module.exports.handler = async (event, context) => {
	console.log(JSON.stringify(event, undefined, 4));
}
EOF
    filename = "index.js"
  }
}

resource "aws_lambda_function" "lambda" {
  function_name = "sheduler_example-${random_id.id.hex}-function"

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  handler = "index.handler"
  runtime = "nodejs14.x"
  role    = aws_iam_role.lambda_exec.arn
}

data "aws_iam_policy_document" "lambda_exec_role_policy" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:*:*:*"
    ]
  }
}

resource "aws_cloudwatch_log_group" "loggroup" {
  name              = "/aws/lambda/${aws_lambda_function.lambda.function_name}"
  retention_in_days = 14
}

resource "aws_iam_role_policy" "lambda_exec_role" {
  role   = aws_iam_role.lambda_exec.id
  policy = data.aws_iam_policy_document.lambda_exec_role_policy.json
}

resource "aws_iam_role" "lambda_exec" {
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
	{
	  "Action": "sts:AssumeRole",
	  "Principal": {
		"Service": "lambda.amazonaws.com"
	  },
	  "Effect": "Allow"
	}
  ]
}
EOF
}

# scheduler

resource "aws_sfn_state_machine" "delayer" {
  name = "sheduler_example-${random_id.id.hex}-delayer"
  role_arn = aws_iam_role.states_exec.arn

  definition = <<EOF
{
  "StartAt": "Wait",
  "States": {
    "Wait": {
      "Type": "Wait",
      "SecondsPath": "$.delay_seconds",
      "Next": "Call function"
    },
    "Call function": {
      "Type": "Task",
      "Resource": "${aws_lambda_function.lambda.arn}",
      "End": true
    }
  }
}
EOF
}

resource "aws_sfn_state_machine" "scheduler" {
  name = "sheduler_example-${random_id.id.hex}-scheduler"
  role_arn = aws_iam_role.states_exec.arn

  definition = <<EOF
{
  "StartAt": "Wait",
  "States": {
    "Wait": {
      "Type": "Wait",
      "TimestampPath": "$.at",
      "Next": "Call function"
    },
    "Call function": {
      "Type": "Task",
      "Resource": "${aws_lambda_function.lambda.arn}",
      "End": true
    }
  }
}
EOF
}

data "aws_iam_policy_document" "states_exec_role_policy" {
  statement {
    actions = [
      "lambda:InvokeFunction",
    ]
    resources = [
			aws_lambda_function.lambda.arn
    ]
  }
}

resource "aws_iam_role_policy" "states_exec_role" {
  role   = aws_iam_role.states_exec.id
  policy = data.aws_iam_policy_document.states_exec_role_policy.json
}

resource "aws_iam_role" "states_exec" {
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
	{
	  "Action": "sts:AssumeRole",
	  "Principal": {
		"Service": "states.amazonaws.com"
	  },
	  "Effect": "Allow"
	}
  ]
}
EOF
}

output "delayer_arn" {
  value = aws_sfn_state_machine.delayer.arn
}

output "scheduler_arn" {
  value = aws_sfn_state_machine.scheduler.arn
}
