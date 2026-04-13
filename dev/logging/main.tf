# REMOTE STATE — EKS

data "terraform_remote_state" "eks" {
  backend = "s3"
  config = {
    bucket = "ochirdorj-terraform-kubernetes-backend-bucket"
    key    = "dev/eks/terraform.tfstate"
    region = "us-east-1"
  }
}

module "logging" {
  source = "git::https://github.com/ochirdorj/infra-core-observability-logging-template.git?ref=3ced704274b72a7601080605fc44c0fd78b06154"

  cluster_name       = data.terraform_remote_state.eks.outputs.cluster_name
  oidc_provider_arn  = data.terraform_remote_state.eks.outputs.oidc_provider_arn
  oidc_provider_url  = data.terraform_remote_state.eks.outputs.oidc_provider_url
  namespace          = var.namespace
  log_retention_days = var.log_retention_days
  tags               = var.tags
}