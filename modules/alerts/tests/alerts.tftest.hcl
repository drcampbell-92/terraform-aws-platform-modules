mock_provider "aws" {
  mock_resource "aws_sns_topic" {
    defaults = {
      arn = "arn:aws:sns:us-east-1:123456789012:mock-topic"
    }
  }
}

variables {
  name_prefix            = "uptime-test"
  allowed_publisher_arns = ["arn:aws:iam::123456789012:role/uptime-test-checker-role"]
}

run "uses_naming_standard" {
  command = apply

  assert {
    condition     = aws_sns_topic.alerts.name == "uptime-test-alerts"
    error_message = "Topic name must follow the uptime-<env>-<component> standard."
  }
}

run "encrypts_by_default" {
  command = apply

  assert {
    condition     = aws_sns_topic.alerts.kms_master_key_id == "alias/aws/sns"
    error_message = "The topic must be encrypted at rest by default."
  }
}

run "creates_no_subscriptions_by_default" {
  command = apply

  assert {
    condition     = length(aws_sns_topic_subscription.email) == 0
    error_message = "No subscription should exist when no emails are given."
  }
}

run "creates_one_subscription_per_email" {
  command = apply

  variables {
    email_addresses = ["first@example.com", "second@example.com"]
  }

  assert {
    condition     = length(aws_sns_topic_subscription.email) == 2
    error_message = "Each email address must get exactly one subscription."
  }
}


run "denies_insecure_transport" {
  command = apply

  assert {
    condition     = strcontains(aws_sns_topic_policy.alerts.policy, "aws:SecureTransport")
    error_message = "The topic policy must deny publishing without TLS."
  }
}

run "denies_unlisted_publishers" {
  command = apply

  assert {
    condition     = strcontains(aws_sns_topic_policy.alerts.policy, "uptime-test-checker-role")
    error_message = "The listed publisher must appear in the topic policy."
  }

  assert {
    condition     = strcontains(aws_sns_topic_policy.alerts.policy, "\"aws:PrincipalArn\"")
    error_message = "The deny statement must use the aws:PrincipalArn condition key, spelled exactly."
  }
}

run "requires_a_publishers" {
  command = plan

  variables {
    allowed_publisher_arns = []
  }

  expect_failures = [var.allowed_publisher_arns]
}

run "rejects_invalid_email" {
  command = plan

  variables {
    email_addresses = ["not-an-email"]
  }

  expect_failures = [var.email_addresses]
}