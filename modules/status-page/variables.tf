variable "name_prefix" {
  type        = string
  description = "Prefix for every resource name, for example uptime-dev"

  validation {
    condition     = can(regex("^[a-z0-9-]{3,40}$", var.name_prefix))
    error_message = "name_prefix must be 3 to 40 characters of lowercase letters, numbers, and hyphens."
  }
}

variable "page_title" {
  type        = string
  description = "Heading shown on the status page"
  default     = "Service status"

  validation {
    condition     = can(regex("^[A-Za-z0-9 .,'-]{1,60}$", var.page_title))
    error_message = "page_title may only contain letters, numbers, spaces, and . , ' - and must be 1 to 60 characters."
  }
}

variable "price_class" {
  type        = string
  description = "CloudFront price class. PriceClass_100 uses the lowest-cost edge locations."
  default     = "PriceClass_100"

  validation {
    condition     = contains(["PriceClass_100", "PriceClass_200", "PriceClass_All"], var.price_class)
    error_message = "price_class must be PriceClass_100, PriceClass_200, or PriceClass_All."
  }
}

variable "force_destroy" {
  type        = bool
  description = "Allow Terraform to delete the bucket even when it contains files"
  default     = false
}