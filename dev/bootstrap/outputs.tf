# OUTPUTS

output "dynamodb_table_name" {
  description = "DynamoDB table name for Terraform state locking"
  value       = module.dynamodb.table_name
}

output "dynamodb_table_arn" {
  description = "DynamoDB table ARN"
  value       = module.dynamodb.table_arn
}