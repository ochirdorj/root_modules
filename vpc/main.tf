module "vpc" {
  source = "git::https://github.com/ochirdorj/vpc.git?ref=d595bc1ca2222b805335966b15ff164fcf71a1a4"

  project              = var.project
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  tags                 = var.tags
}
