mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
    }
  }

  mock_resource "aws_iam_policy" {
    defaults = {
      arn = "arn:aws:iam::123456789012:policy/mock-boundary"
    }
  }
}

variables {
  name_prefix         = "uptime-test"
  environment         = "dev"
  budget_alert_emails = ["alerts@example.com"]
}

run "uses_naming_standard" {
  command = apply

  assert {
    condition     = aws_iam_policy.boundary.name == "uptime-test-workload-boundary"
    error_message = "Boundary name must follow the naming standard."
  }

  assert {
    condition     = aws_budgets_budget.monthly.name == "uptime-test-monthly"
    error_message = "Budget name must follow the naming standard."
  }
}

run "limits_boundary_to_prefix" {
  command = apply

  assert {
    condition     = strcontains(aws_iam_policy.boundary.policy, "table/uptime-test-*")
    error_message = "Table access must be limited to the environment prefix."
  }

  assert {
    condition     = strcontains(aws_iam_policy.boundary.policy, "function:uptime-test-*")
    error_message = "Function access must be limited to the environment prefix."
  }
}

run "grants_no_iam_actions" {
  command = apply

  assert {
    condition     = !strcontains(aws_iam_policy.boundary.policy, "iam:")
    error_message = "The boundary must not allow any IAM actions."
  }
}

run "contains_no_wildcards" {
  command = apply

  assert {
    condition     = !strcontains(aws_iam_policy.boundary.policy, "\"*\"")
    error_message = "The boundary must not contain a bare wildcard action or resource."
  }
}

run "filters_budget_by_environment" {
  command = apply

  assert {
    condition     = contains(one(aws_budgets_budget.monthly.cost_filter).values, "user:Environment$dev")
    error_message = "The budget must track only this environment's spending."
  }
}

run "alerts_on_actual_and_forecast" {
  command = apply

  assert {
    condition     = length(aws_budgets_budget.monthly.notification) == 2
    error_message = "The budget must alert on actual and forecasted spend."
  }
}

run "rejects_unknown_environment" {
  command = plan

  variables {
    environment = "staging"
  }

  expect_failures = [var.environment]
}

run "requires_a_budget_email" {
  command = plan

  variables {
    budget_alert_emails = []
  }

  expect_failures = [var.budget_alert_emails]
}