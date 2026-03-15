variable "scp_name" {
  type = string
  default = "EnforceTag"
}

variable "scp_description" {
  type = string
  default = "SCP to enforce resource tag"
}

variable "scp_path" {
  type = string
  default = null
}

variable "scp_type" {
  type = string
  default = "SERVICE_CONTROL_POLICY"
}

variable "include_root" {
  type = bool
  description = "include root_id = true, exlclude root_id = false"
  default = false
}

variable "target_ou_names" {
  type = list(string)
  description = "scp target ou name, leave it blank, it you don't want to attach scp to ou"
  default = [ "Security" ]
}

variable "target_account_names" {
  type = list(string)
  description = "scp target account names, leave it blank, it you don't want to attach scp to account"
  
}

