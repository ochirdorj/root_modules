variable "enable_logging" {
  type        = bool
  description = "true = enable logging, false = disable logging"
  default     = true
}

variable "bucket_name" {
  type        = string
  description = "Name of the bucket"
  default     = "sandbox-use1-ap13-s3-testing-example"
}

variable "lock_object" {
  type        = bool
  description = "Choose object lock true or false"
  default     = false
}

variable "tag_Environment" {
  type        = string
  description = "Environment"
  default     = "Dev"
}

variable "tag_Managed_By" {
  type        = string
  description = "Name of the tool"
  default     = "Terraform"
}

variable "tag_Project" {
  type        = string
  description = "Project name"
  default     = "ap13"
}

variable "tag_Team" {
  type        = string
  description = "Team"
  default     = "DevOps"
}

variable "tag_Owner" {
  type        = string
  description = "Owner"
  default     = "Tugsuu"
}

variable "bucket_versioning_status" {
  type        = string
  description = "Configuration of versioning. Make is Enabled or Suspended"
  default     = "Suspended"
}

variable "object_lock_mode" {
  type        = string
  description = "Strong protection mode. Even root user is unable to delete the object. Make it COMPLIANCE or GOVERNANCE, delete the resource if you don't want retention"
  default     = "GOVERNANCE"
}

variable "years" {
  type        = string
  description = "Object lock retention year"
  default     = "1"
}

variable "block_acls" {
  type        = bool
  description = "true or false in block public acls"
  default     = true
}

variable "block_policy" {
  type        = bool
  description = "true or false in block public policy"
  default     = true
}

variable "ignore_acls" {
  type        = bool
  description = "true or false in ignore public acls"
  default     = true
}

variable "restrict_buckets" {
  description = "true or false restrict public buckets"
  type        = bool
  default     = true
}

variable "enable_life_cycle_rules" {
  type        = bool
  description = "true = enable or false = disable lifecycel policy"
  default     = false
}

variable "object_prefix" {
  type        = string
  description = "This is object prefix. Use it when you apply lifecycle rule to the object"
  default     = "log/"
}

variable "object_tag" {
  type        = string
  description = <<EOT
  "This object tag. Use it when you apply lifecycle rule to the object.
   Keep in mine object tag and object prefix both needed to be satisfied in order to apply lifecycle rule"
   EOT
  default     = "dev"
}

variable "current_transition_days" {
  type        = number
  description = "number of days after current object to transit different storage class"
  default     = 60
}

variable "current_transition_storage_class" {
  type        = string
  description = <<EOT
  "transition storage type of current object. Choose one of STANDARD, STANDARD_IA, ONEZONE_IA,
   INTELLIGENT_TIERING, DEEP_ARCHIVE, REDUCED_REDUNDANCY"
   EOT
  default     = "STANDARD_IA"
}

variable "current_expiration_days" {
  type        = number
  description = "The number of days after which the current object version will be permanently deleted"
  default     = 365
}

variable "non_current_transition_days" {
  type        = string
  description = "number of days after non current object to transit different storage class"
  default     = "30"
}

variable "non_current_transition_storage_class" {
  type        = string
  description = <<EOT
  "non current object will transit to this storage class. choose one of STANDARD, STANDARD_IA, ONEZONE_IA,
   INTELLIGENT_TIERING, DEEP_ARCHIVE, REDUCED_REDUNDANCY"
   EOT
  default     = "STANDARD_IA"
}

variable "non_current_expiration_days" {
  type        = number
  description = "The number of days after which the non current object version will be permanently deleted"
  default     = 365
}

variable "enable_encryption" {
  type        = bool
  description = "true encryption enabled, false encryption disabled"
  default     = false
}

variable "sse_algorithm" {
  type        = string
  description = "choose aws:kms , AES256, "
  default     = "aws:kms"
}

variable "kms_key_arn" {
  type        = string
  description = "enter kms cumtomer managed key arn"
  default     = ""
}

variable "transfer_acceleration" {
  type        = string
  description = "Enable or Suspended transfer acceleration"
  default     = "Suspended"
}

variable "website_enable" {
  type        = bool
  description = "Static website hosting. Enable = true, Disable = false"
  default     = false
}

variable "key_prefix_equals" {
  type        = string
  description = <<EOT
  "The object key prefix used as a condition for the routing rule. Requests with keys
   starting with this prefix will trigger the redirect"
   EOT
  default     = "docs/"
}

variable "replace_key_prefix_with" {
  type        = string
  description = <<EOT
  "The new key prefix that replaces the matched prefix in the redirect. 
  Requests matching the condition will be redirected to this prefix."
  EOT
  default     = "documents/"
}

variable "enable_replication" {
  description = "Enable cross-region replication"
  type        = bool
  default     = false
}

variable "replication_destination_bucket_arn" {
  description = "ARN of the destination bucket for replication"
  type        = string
  default     = ""
}

variable "dynamodb_table_name" {
  description = "Name of the DynamoDB table for Terraform state locking"
  type        = string
  default = "eks-terraform-state-lock"
}