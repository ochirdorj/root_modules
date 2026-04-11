# REMOTE STATE — VPC

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "ochirdorj-terraform-kubernetes-backend-bucket"
    key    = "dev/vpc/terraform.tfstate"
    region = "us-east-1"
  }
}

# EKS CLUSTER

module "eks" {
  source = "git::https://github.com/ochirdorj/infra-core-compute-eks-template.git?ref=26e9bfe5e76314d546e11ca6622d697ea717f48d"

  cluster_name        = var.cluster_name
  cluster_version     = var.cluster_version
  private_subnet_ids  = data.terraform_remote_state.vpc.outputs.private_subnet_ids
  public_access_cidrs = var.public_access_cidrs
  instance_types      = var.instance_types
  capacity_type       = var.capacity_type
  desired_size        = var.desired_size
  min_size            = var.min_size
  max_size            = var.max_size
  tags                = var.tags
}