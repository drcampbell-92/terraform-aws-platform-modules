output "function_name" {
  description = "Name of the checker Lambda function"
  value       = aws_lambda_function.checker.function_name
}

output "function_arn" {
  description = "ARN of the checker Lambda function"
  value       = aws_lambda_function.checker.arn
}

output "table_name" {
  description = "Name of the results table"
  value       = aws_dynamodb_table.results.name
}

output "table_arn" {
  description = "ARN of the results table"
  value       = aws_dynamodb_table.results.arn
}

output "schedule_name" {
  description = "Name of the EventBridge schedule"
  value       = aws_scheduler_schedule.checker.name
}

output "role_arn" {
  description = "ARN of the checker's execution role, for resource policies that grant it access"
  value       = aws_iam_role.checker.arn
}