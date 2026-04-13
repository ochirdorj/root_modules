# OUTPUTS

output "fluent_bit_role_arn" {
  description = "ARN of Fluent Bit IAM role"
  value       = module.logging.fluent_bit_role_arn
}

output "application_log_group" {
  description = "CloudWatch log group for application logs"
  value       = module.logging.application_log_group
}

output "dataplane_log_group" {
  description = "CloudWatch log group for dataplane logs"
  value       = module.logging.dataplane_log_group
}

output "host_log_group" {
  description = "CloudWatch log group for host logs"
  value       = module.logging.host_log_group
}