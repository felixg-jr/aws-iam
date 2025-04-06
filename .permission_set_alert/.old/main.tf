# Creates an SNS topic
resource "aws_sns_topic" "aws_ps_create" {
  name = "aws-permission-sets"
}

# Attaches the policy
resource "aws_sns_topic_policy" "default" {
  arn    = aws_sns_topic.aws_ps_create.arn
  policy = data.aws_iam_policy_document.sns_topic_policy.json
}

# Resource that will subscribe to the SNS topic
resource "aws_sns_topic_subscription" "user_updates_email_target" {
  topic_arn = aws_sns_topic.aws_ps_create.arn
  protocol  = "email"
  endpoint  = "fprasca26@gmail.com"
}

# EventBridge rule creation
resource "aws_cloudwatch_event_rule" "ps_created" {
  name        = "capture-aws-permission-set-creation"
  description = "Capture each permission set created via AWS SSO"

  event_pattern = jsonencode({
    detail-type = [
      "AWS API Call via CloudTrail"
    ], detail = { eventSource = ["sso.amazonaws.com"], eventName = ["CreatePermissionSet"]}
  })
}

# EventBridge rule when triggered, destination to go toter
resource "aws_cloudwatch_event_target" "sns" {
  rule      = aws_cloudwatch_event_rule.ps_created.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.aws_ps_create.arn
}

# {
#   "source": ["aws.sso"],
#   "detail-type": ["AWS API Call via CloudTrail"],
#   "detail": {
#     "eventSource": ["sso.amazonaws.com"],
#     "eventName": ["CreatePermissionSet"]
#   }
# }



