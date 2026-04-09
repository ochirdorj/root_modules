# VPC

module "vpc" {
  source = "git::https://github.com/ochirdorj/infra-core-network-vpc-template.git?ref=b55981153e98bc4ceac59f5802f2f2110f586401"

  vpc_name             = var.vpc_name
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  single_nat_gateway   = var.single_nat_gateway
  tags                 = var.tags
}