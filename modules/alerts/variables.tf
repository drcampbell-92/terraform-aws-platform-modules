variable "name_prefix" {
  type        = string
  description = "Prefix for every resource name, for example uptime-dev"

  validation {
    condition     = can(regex("^[a-z0-9-]{3,40}$", var.name_prefix))
    error_message = "name_prefix must be 3 to 40 characters of lowercase letters, numbers, and hyphens."
  }
}

variable "allowed_publisher_arns" {
  type        = list(string)
  description = "IAM role ARNs allowed to publish to the topic. Every other principal is denied."

  validation {
    condition     = length(var.allowed_publisher_arns) > 0
    error_message = "At least one publisher must be listed. A topic must declare who can publish to it."
  }

  validation {
    condition     = alltrue([for arn in var.allowed_publisher_arns : startswith(arn, "arn:aws:iam::")])
    error_message = "Every publisher must be an IAM ARN starting with arn:aws:iam::."
  }
}

variable "email_addresses" {
  type        = list(string)
  description = "Email addresses that receive alerts. Each must confirm the subscription by email."
  default     = []

  validation {
    condition     = alltrue([for email in var.email_addresses : can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", email))])
    error_message = "Every entry in email_addresses must be a valid email address."
  }
}

variable "kms_master_key_id" {
  type        = string
  description = "KMS key used to encrypt the topic at rest"
  default     = "alias/aws/sns"
}