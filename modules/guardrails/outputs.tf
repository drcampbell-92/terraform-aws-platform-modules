output "permissions_boundary_arn" {
  description = "ARN of the workload permissions boundary, attached to every role the platform creates"
  value       = aws_iam_policy.boundary.arn
}

output "budget_name" {
  description = "Name of the monthly budget"
  value       = aws_budgets_budget.monthly.name
}