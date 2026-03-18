variable "instance_type" {
  type = list(string)
  description = "ec2 instance type"
  default = ["t3.medium", "c5.large", "c6i.large"]
}

variable "Environment" {
  type = string
  description = "tag for asg"
  default = "sandbox"
}

variable "Managed_by" {
  type = string
  description = "Managed by tag"
  default = "terraform"
}

variable "Project" {
  type = string
  description = "tag for asg"
  default = "project-13"
}

variable "Team" {
  type = string
  description = "tag for asg"
  default = "ap13"
}

variable "Owner" {
  type = string
  description = "tag for asg"
  default = "Tugsuu"
}

variable "root_volume_size" {
  type = number
  description = "size of ebs volume"
  default = 20
}

variable "vpc_id" {
  type = string
  description = "VPC ID"
  default = "vpc-0cbbdf4c84f9c79dd"
}

variable "lambda_subnets" {
  type = list(string)
  description = "private subnets"
  default = [
    "subnet-01f55f939b6b4de8d",
    "subnet-07ef815e17eb4894a"
  ]
}

variable "github_app_credentials_secret_name" {
    type = string
    description = "just leave it as is"
    default = "self_hosted_runner"
  }

variable "runner_labels" {
  type = string
  description = "runner labels"
  default = "self-hosted, linux, x64"
}

variable "launch_template" {
  type = string
  description = "name of the launch template"
  default = "github-runner-lt"
}

variable "create_spot_role" {
  type = bool
  description = "enable or disable service linked role"
  default = true
}
variable "stage_name" {
type = string
description = "API Gateway stage name"  
default = "dev"
}

variable "kms_key_arn" {
  type = string
  description = "KMS Key ARN for encrypting secrets (optional, but recommended)"
  default = null
}

variable "image_id" {
  description = "AMI ID for the self hosted runner instances. "
  type        = string
  default     = "ami-01f3bee89838bc457"
}

variable "webhook_lambda_zip_path" {
  type        = string
  description = "Path to the pre-built webhook validator Lambda zip file"
  default     = "${path.module}/webhook_validator.zip"
}

variable "webhook_secret_key" {
  type        = string
  description = "Key name in the Secrets Manager JSON that holds the GitHub webhook secret"
  default     = "webhook_secret"
}

variable "aws_region" {
  type = string
  description = "aws region"
}