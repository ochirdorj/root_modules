# MONITORING VARIABLES

variable "namespace" {
  type        = string
  description = "Kubernetes namespace for monitoring stack"
  default     = "monitoring"
}

variable "grafana_admin_password" {
  type        = string
  description = "Grafana admin password"
  sensitive   = true
  default     = "admin123!"
}

variable "prometheus_retention" {
  type        = string
  description = "Prometheus data retention period"
  default     = "7d"
}