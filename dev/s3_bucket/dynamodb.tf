# DYNAMODB TABLE — TERRAFORM STATE LOCKING

resource "aws_dynamodb_table" "terraform_state_lock" {
  name         = var.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  tags = {
    Environment = var.tag_Environment
    Managed_By  = var.tag_Managed_By
    Project     = var.tag_Project
    Team        = var.tag_Team
    Owner       = var.tag_Owner
  }
}