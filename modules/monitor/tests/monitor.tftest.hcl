mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
    }
  }

  mock_resource "aws_iam_role" {
    defaults = {
      arn = "arn:aws:iam::123456789012:role/mock-role"
    }
  }

  mock_resource "aws_lambda_function" {
    defaults = {
      arn = "arn:aws:lambda:us-east-1:123456789012:function:mock-function"
    }
  }

  mock_resource "aws_dynamodb_table" {
    defaults = {
      arn = "arn:aws:dynamodb:us-east-1:123456789012:table/mock-table"
    }
  }

  mock_resource "aws_cloudwatch_log_group" {
    defaults = {
      arn = "arn:aws:logs:us-east-1:123456789012:log-group:/aws/lambda/mock"
    }
  }
}

variables {
  name_prefix = "uptime-test"
  targets = {
    example = "https://example.com"
  }
}

run "uses_naming_standard" {
  command = apply

  assert {
    condition     = aws_lambda_function.checker.function_name == "uptime-test-checker"
    error_message = "Function name must follow the uptime-<env>-<component> standard."
  }

  assert {
    condition     = aws_dynamodb_table.results.name == "uptime-test-results"
    error_message = "Table name must follow the uptime-<env>-<component> standard."
  }
}

run "grants_no_optional_permissions_by_default" {
  command = apply

  assert {
    condition     = !strcontains(aws_iam_role_policy.checker.policy, "sns:Publish")
    error_message = "The checker must not get sns:Publish when no alert topic is configured."
  }

  assert {
    condition     = !strcontains(aws_iam_role_policy.checker.policy, "s3:PutObject")
    error_message = "The checker must not get s3:PutObject when no status bucket is configured."
  }
}

run "grants_publish_only_to_the_given_topic" {
  command = apply

  variables {
    alert_topic_arn = "arn:aws:sns:us-east-1:123456789012:uptime-test-alerts"
  }

  assert {
    condition     = strcontains(aws_iam_role_policy.checker.policy, "arn:aws:sns:us-east-1:123456789012:uptime-test-alerts")
    error_message = "sns:Publish must be scoped to the configured topic."
  }
}

run "limits_status_write_to_one_object" {
  command = apply

  variables {
    status_bucket_name = "uptime-test-status"
  }

  assert {
    condition     = strcontains(aws_iam_role_policy.checker.policy, "arn:aws:s3:::uptime-test-status/status.json")
    error_message = "s3:PutObject must be scoped to the status file."
  }

  assert {
    condition     = !strcontains(aws_iam_role_policy.checker.policy, "uptime-test-status/*")
    error_message = "s3:PutObject must not cover the whole bucket."
  }
}

run "rejects_non_http_targets" {
  command = plan

  variables {
    targets = {
      bad = "ftp://example.com"
    }
  }

  expect_failures = [var.targets]
}

run "scales_timeout_with_target_count" {
  command = apply

  variables {
    targets = {
      a = "https://example.com"
      b = "https://example.org"
      c = "https://example.net"
    }
    check_timeout_seconds = 5
  }

  assert {
    condition     = aws_lambda_function.checker.timeout == 25
    error_message = "Timeout must equal targets times check timeout, plus 10 seconds."
  }
}