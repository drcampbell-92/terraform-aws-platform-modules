locals {
  topic_name = "${var.name_prefix}-alerts"
}

resource "aws_sns_topic" "alerts" {
  name              = local.topic_name
  kms_master_key_id = var.kms_master_key_id
}

resource "aws_sns_topic_policy" "alerts" {
  arn = aws_sns_topic.alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "sns:Publish"
        Resource  = aws_sns_topic.alerts.arn
        Condition = {
          Bool = { "aws:SecureTransport" = "false" }
        }
      },
      {
        Sid       = "AllowListedPublishers"
        Effect    = "Allow"
        Principal = { AWS = var.allowed_publisher_arns }
        Action    = "sns:Publish"
        Resource  = aws_sns_topic.alerts.arn
      },
      {
        Sid       = "DenyUnlistedPublishers"
        Effect    = "Deny"
        Principal = "*"
        Action    = "sns:Publish"
        Resource  = aws_sns_topic.alerts.arn
        Condition = {
          ArnNotEquals = { "aws:PrincipalArn" = var.allowed_publisher_arns }
        }
      },
    ]
  })
}

resource "aws_sns_topic_subscription" "email" {
  for_each = toset(var.email_addresses)

  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = each.value
}