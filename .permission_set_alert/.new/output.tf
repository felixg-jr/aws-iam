output "sns_topic_arn" {
  description = "The ARN of the SNS topic for permission set assignments"
  value       = aws_sns_topic.ps_assign.arn
}
