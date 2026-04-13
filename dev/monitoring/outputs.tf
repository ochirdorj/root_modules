# OUTPUTS

output "grafana_service_name" {
  description = "Grafana service name"
  value       = module.monitoring.grafana_service_name
}

output "prometheus_service_name" {
  description = "Prometheus service name"
  value       = module.monitoring.prometheus_service_name
}

output "namespace" {
  description = "Monitoring namespace"
  value       = module.monitoring.namespace
}