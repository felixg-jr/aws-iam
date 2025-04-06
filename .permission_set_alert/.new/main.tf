# EventBridge Rule

resource "aws_cloudwatch_event_rule" "console" {
  name        = "capture-permission-set-assignment"
  description = "Capture each time a permission set is assigned."
  event_pattern = jsonencode({
    source      = ["aws.sso"]
    detail-type = ["AWS API Call via CloudTrail"]
    detail = {
      eventSource = ["sso.amazonaws.com"]
      eventName   = ["CreateAccountAssignment"]
    }
  })
}

# EventBridge Target

resource "aws_cloudwatch_event_target" "lambda" {
  rule      = aws_cloudwatch_event_rule.console.name
  target_id = "SendToLambda"
  arn       = aws_lambda_function.test_lambda.arn
}


# Lambda Permission

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.test_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.console.arn
}

# Lambda Function

resource "aws_lambda_function" "test_lambda" {
  filename      = "lambda_function_payload.zip"
  function_name = "lambda_permission_set_assignment"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "lambda.lambda_handler"

  source_code_hash = data.archive_file.lambda.output_base64sha256

  runtime = "python3.13"

  environment {
    variables = {
      SNS_TOPIC_ARN = "arn:aws:sns:us-east-1:988895912177:aws-permission-set-assignment"
    }
  }
}



resource "aws_lambda_function_event_invoke_config" "example" {
  function_name = aws_lambda_function.test_lambda.function_name
}


resource "aws_iam_role" "iam_for_lambda" {
  name               = "iam_for_lambda"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_policy" "zelda" {
  name        = "test2"
  description = "A test policy"
  policy      = data.aws_iam_policy_document.lambda_policy.json
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "sns" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.zelda.arn
}

// Lambda Stuff Ends

// SNS Stuff

resource "aws_sns_topic" "ps_assign" {
  name = "aws-permission-set-assignment"
}

resource "aws_sns_topic_subscription" "rocco" {
  topic_arn = aws_sns_topic.ps_assign.arn
  protocol  = "email"
  endpoint  = "name@gmail.com"
}

resource "aws_sns_topic_policy" "default" {
  arn    = aws_sns_topic.ps_assign.arn
  policy = data.aws_iam_policy_document.sns_topic_policy.json
}

# Setup a CloudTrail

# CloudTrail to capture SSO events
resource "aws_cloudtrail" "trail" {
  name                          = "sso-event-trail"
  s3_bucket_name                = aws_s3_bucket.trail_bucket.id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_logging                = true

  event_selector {
    read_write_type           = "All"
    include_management_events = true
  }
}

resource "aws_s3_bucket" "trail_bucket" {
  bucket = "sso-cloudtrail-logs-988895912177"
}

resource "aws_s3_bucket_policy" "trail_bucket_policy" {
  bucket = aws_s3_bucket.trail_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.trail_bucket.arn}/AWSLogs/*"
      },
      {
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:GetBucketAcl"
        Resource  = aws_s3_bucket.trail_bucket.arn
      }
    ]
  })
}
