# DYNAMODB — TERRAFORM STATE LOCK TABLE

module "dynamodb" {
  source = "git::https://github.com/ochirdorj/infra-core-database-dynamodb-template.git?ref=79e254da7d49358149d5a343af29133ebece73d4"

  table_name  = var.table_name
  billing_mode = var.billing_mode
  hash_key    = var.hash_key
  enable_cmk  = var.enable_cmk
  enable_pitr = var.enable_pitr

  tag_Environment = var.tag_Environment
  tag_Managed_By  = var.tag_Managed_By
  tag_Project     = var.tag_Project
  tag_Team        = var.tag_Team
  tag_Owner       = var.tag_Owner
}