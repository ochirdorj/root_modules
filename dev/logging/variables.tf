# LOGGING VARIABLES

variable "namespace" {
  type        = string
  description = "Kubernetes namespace for Fluent Bit"
  default     = "logging"
}

variable "log_retention_days" {
  type        = number
  description = "CloudWatch log retention in days"
  default     = 7
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources"
  default = {
    Environment = "dev"
    Managed_By  = "terraform"
    Project     = "kubernetes"
    Team        = "devops"
    Owner       = "tugsuu"
  }
}