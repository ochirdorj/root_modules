# VPC VARIABLES

variable "vpc_name" {
  type        = string
  description = "Name of the VPC"
  default     = "dev-eks-vpc"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for public subnets"
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for private subnets"
  default     = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
}

variable "single_nat_gateway" {
  type        = bool
  description = "Use single NAT gateway to save cost"
  default     = true
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources"
  default = {
    Environment = "dev"
    Managed_By  = "terraform"
    Project     = "kubernetes"
    Team        = "devops"
    Owner       = "tugsuu"
  }
}

##testing for deployment