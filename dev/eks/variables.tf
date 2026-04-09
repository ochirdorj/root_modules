# EKS VARIABLES

variable "cluster_name" {
  type        = string
  description = "Name of the EKS cluster"
  default     = "dev-eks-cluster"
}

variable "cluster_version" {
  type        = string
  description = "Kubernetes version"
  default     = "1.31"
}

variable "public_access_cidrs" {
  type        = list(string)
  description = "CIDR blocks that can access EKS public API"
  default     = ["0.0.0.0/0"]
}

variable "instance_types" {
  type        = list(string)
  description = "EC2 instance types for node group"
  default     = ["t3.medium"]
}

variable "capacity_type" {
  type        = string
  description = "ON_DEMAND or SPOT"
  default     = "ON_DEMAND"
}

variable "desired_size" {
  type        = number
  description = "Desired number of worker nodes"
  default     = 2
}

variable "min_size" {
  type        = number
  description = "Minimum number of worker nodes"
  default     = 1
}

variable "max_size" {
  type        = number
  description = "Maximum number of worker nodes"
  default     = 3
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