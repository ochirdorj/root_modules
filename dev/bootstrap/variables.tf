# DYNAMODB VARIABLES

variable "table_name" {
  type        = string
  description = "Name of the DynamoDB table"
  default     = "eks-terraform-state-lock"
}

variable "billing_mode" {
  type        = string
  description = "PAY_PER_REQUEST or PROVISIONED"
  default     = "PAY_PER_REQUEST"
}

variable "hash_key" {
  type        = string
  description = "Hash key for the DynamoDB table"
  default     = "LockID"
}

variable "enable_pitr" {
  type        = bool
  description = "Enable point in time recovery"
  default     = true
}

variable "enable_cmk" {
  type        = bool
  description = "Enable Customer Managed KMS key"
  default     = false
}

# TAGS

variable "tag_Environment" {
  type        = string
  description = "Environment"
  default     = "dev"
}

variable "tag_Managed_By" {
  type        = string
  description = "Name of the tool"
  default     = "terraform"
}

variable "tag_Project" {
  type        = string
  description = "Project name"
  default     = "kubernetes"
}

variable "tag_Team" {
  type        = string
  description = "Team"
  default     = "devops"
}

variable "tag_Owner" {
  type        = string
  description = "Owner"
  default     = "tugsuu"
}