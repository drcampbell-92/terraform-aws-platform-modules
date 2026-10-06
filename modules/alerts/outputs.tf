output "topic_arn" {
  description = "ARN of the alerts topic, passed to the monitor module"
  value       = aws_sns_topic.alerts.arn
}

output "topic_name" {
  description = "Name of the alerts topic"
  value       = aws_sns_topic.alerts.name
}