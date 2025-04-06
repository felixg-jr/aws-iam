data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "lambda_policy" {
  statement {
    sid = "SNSActions"
    effect = "Allow"
    actions = [
        "sns:Publish",
        ]
    resources = [aws_sns_topic.ps_assign.arn]
  }

  statement {
    sid = "SSOActions"
    effect = "Allow"
    actions = [
        "sso:ListInstances",
        "sso:DescribePermissionSet",
        ]
    resources = [
    "arn:aws:sso:::instance/*", 
    "arn:aws:sso:::permissionSet/*"
    ] # Adjust this ARN based on your actual SSO instance and permission sets
  }
}

data "aws_iam_policy_document" "sns_topic_policy" {
  statement {
    effect  = "Allow"
    actions = ["SNS:Publish"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    resources = [aws_sns_topic.ps_assign.arn]
  }
}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "lambda.py"
  output_path = "lambda_function_payload.zip"
}
