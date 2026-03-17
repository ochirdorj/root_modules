variable "project" {
  description = "Project name used for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g. prod, dev)"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default = "us-east-1"
}

variable "instance_type" {
  description = "Instance type for the AMI builder (t3.medium recommended for faster installs)"
  type        = string
  default     = "t3.medium"
}
