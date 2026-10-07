variable "name_prefix" {
  type        = string
  description = "Prefix for every resource name, for example uptime-dev"

  validation {
    condition     = can(regex("^[a-z0-9-]{3,40}$", var.name_prefix))
    error_message = "name_prefix must be 3 to 40 characters of lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  type        = string
  description = "Environment name, used to filter the budget by the Environment tag"

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be dev or prod."
  }
}

variable "monthly_budget_usd" {
  type        = number
  description = "Monthly spending limit in USD for this environment"
  default     = 5

  validation {
    condition     = var.monthly_budget_usd > 0
    error_message = "monthly_budget_usd must be greater than 0."
  }
}

variable "budget_alert_emails" {
  type        = list(string)
  description = "Email addresses that receive budget alerts"

  validation {
    condition     = length(var.budget_alert_emails) > 0
    error_message = "At least one email address is required to receive budget alerts."
  }

  validation {
    condition     = alltrue([for email in var.budget_alert_emails : can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", email))])
    error_message = "Every entry in budget_alert_emails must be a valid email address."
  }
}