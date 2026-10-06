data "aws_caller_identity" "current" {}

locals {
  function_name  = "${var.name_prefix}-checker"
  table_name     = "${var.name_prefix}-results"
  lambda_timeout = min(900, length(var.targets) * var.check_timeout_seconds + 10)

  checker_statements = concat(
    [
      {
        Sid      = "WriteResults"
        Effect   = "Allow"
        Action   = ["dynamodb:PutItem"]
        Resource = [aws_dynamodb_table.results.arn]
      },
      {
        Sid      = "WriteLogs"
        Effect   = "Allow"
        Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = ["${aws_cloudwatch_log_group.checker.arn}:*"]
      },
    ],
    var.alert_topic_arn == null ? [] : [
      {
        Sid      = "PublishAlerts"
        Effect   = "Allow"
        Action   = ["sns:Publish"]
        Resource = [var.alert_topic_arn]
      },
    ],
    var.status_bucket_name == null ? [] : [
      {
        Sid      = "WriteStatusFile"
        Effect   = "Allow"
        Action   = ["s3:PutObject"]
        Resource = ["arn:aws:s3:::${var.status_bucket_name}/${var.status_object_key}"]
      },
    ],
  )
}

data "archive_file" "checker" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/build/checker.zip"
}

resource "aws_dynamodb_table" "results" {
  name         = local.table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "target"
  range_key    = "checked_at"

  attribute {
    name = "target"
    type = "S"
  }

  attribute {
    name = "checked_at"
    type = "S"
  }

  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }

  point_in_time_recovery {
    enabled = var.enable_point_in_time_recovery
  }
}

resource "aws_cloudwatch_log_group" "checker" {
  name              = "/aws/lambda/${local.function_name}"
  retention_in_days = var.log_retention_days
}

resource "aws_iam_role" "checker" {
  name                 = "${local.function_name}-role"
  permissions_boundary = var.permissions_boundary_arn

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "lambda.amazonaws.com" }
        Action    = "sts:AssumeRole"
      },
    ]
  })
}

resource "aws_iam_role_policy" "checker" {
  name = "${local.function_name}-policy"
  role = aws_iam_role.checker.id

  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = local.checker_statements
  })
}

resource "aws_lambda_function" "checker" {
  function_name    = local.function_name
  role             = aws_iam_role.checker.arn
  runtime          = "python3.13"
  handler          = "checker.handler"
  filename         = data.archive_file.checker.output_path
  source_code_hash = data.archive_file.checker.output_base64sha256
  memory_size      = 128
  timeout          = local.lambda_timeout

  environment {
    variables = {
      TABLE_NAME            = aws_dynamodb_table.results.name
      TARGETS               = jsonencode(var.targets)
      TIMEOUT_SECONDS       = tostring(var.check_timeout_seconds)
      RESULT_RETENTION_DAYS = tostring(var.result_retention_days)
      ALERT_TOPIC_ARN       = var.alert_topic_arn == null ? "" : var.alert_topic_arn
      STATUS_BUCKET         = var.status_bucket_name == null ? "" : var.status_bucket_name
      STATUS_KEY            = var.status_object_key
    }
  }

  depends_on = [aws_cloudwatch_log_group.checker]
}

resource "aws_iam_role" "scheduler" {
  name                 = "${local.function_name}-scheduler"
  permissions_boundary = var.permissions_boundary_arn

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "scheduler.amazonaws.com" }
        Action    = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "scheduler" {
  name = "${local.function_name}-scheduler-policy"
  role = aws_iam_role.scheduler.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "InvokeChecker"
        Effect   = "Allow"
        Action   = ["lambda:InvokeFunction"]
        Resource = [aws_lambda_function.checker.arn]
      },
    ]
  })
}

resource "aws_scheduler_schedule" "checker" {
  name                = local.function_name
  schedule_expression = var.schedule_expression
  state               = var.enabled ? "ENABLED" : "DISABLED"

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = aws_lambda_function.checker.arn
    role_arn = aws_iam_role.scheduler.arn

    retry_policy {
      maximum_retry_attempts = 0
    }
  }
}