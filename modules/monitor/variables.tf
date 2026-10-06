variable "name_prefix" {
  type        = string
  description = "Prefix for every resource name, for example uptime-dev"

  validation {
    condition     = can(regex("^[a-z0-9-]{3,40}$", var.name_prefix))
    error_message = "name_prefix must be 3 to 40 characters of lowercase letters, numbers, and hyphens."
  }
}

variable "targets" {
  type        = map(string)
  description = "Map of target names to URLs to check, for example { homepage = \"https://example.com\" }"

  validation {
    condition     = length(var.targets) > 0
    error_message = "targets must contain at least one URL."
  }

  validation {
    condition     = alltrue([for url in values(var.targets) : can(regex("^https?://", url))])
    error_message = "Every target URL must start with http:// or https://."
  }
}

variable "schedule_expression" {
  type        = string
  description = "How often checks run, as an EventBridge Scheduler rate or cron expression"
  default     = "rate(5 minutes)"

  validation {
    condition     = can(regex("^(rate|cron)\\(", var.schedule_expression))
    error_message = "schedule_expression must start with rate( or cron(."
  }
}

variable "enabled" {
  type        = bool
  description = "Whether the schedule runs. Set to false to pause checks without destroying anything."
  default     = true
}

variable "check_timeout_seconds" {
  type        = number
  description = "Seconds to wait for each URL before counting it as down"
  default     = 5

  validation {
    condition     = var.check_timeout_seconds >= 1 && var.check_timeout_seconds <= 30
    error_message = "check_timeout_seconds must be between 1 and 30."
  }
}

variable "result_retention_days" {
  type        = number
  description = "Days to keep check results before DynamoDB deletes them automatically"
  default     = 7
}

variable "log_retention_days" {
  type        = number
  description = "Days to keep the checker's logs"
  default     = 7

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365], var.log_retention_days)
    error_message = "log_retention_days must be a value CloudWatch Logs accepts, such as 7, 14, or 30."
  }
}

variable "enable_point_in_time_recovery" {
  type        = bool
  description = "Whether to enable DynamoDB point-in-time recovery on the results table"
  default     = false
}

variable "alert_topic_arn" {
  type        = string
  description = "SNS topic to notify when a check fails. Null disables alerts."
  default     = null
}

variable "status_bucket_name" {
  type        = string
  description = "Bucket that receives the current status file. Null disables it."
  default     = null
}

variable "status_object_key" {
  type        = string
  description = "Object key for the status file"
  default     = "status.json"
}

variable "permissions_boundary_arn" {
  type        = string
  description = "Permissions boundary attached to every role this module creates. Null attaches none."
  default     = null
}

