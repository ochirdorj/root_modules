data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "ochirdorj-terraform-backend-bucket"
    key    = "infra/vpc_backend/terraform.tfstate"
    region = "us-east-1"
  }
}

module "ami_builder" {
  source = "git::https://github.com/ochirdorj/ami_builder.git?ref=451b185506ffe2d63815ce415bfbf2735c02fef8"

  project       = var.project
  environment   = var.environment
  vpc_id        = data.terraform_remote_state.vpc.outputs.vpc_id
  subnet_id     = data.terraform_remote_state.vpc.outputs.private_subnet_ids[0]
  aws_region    = var.aws_region
  instance_type = var.instance_type
}
