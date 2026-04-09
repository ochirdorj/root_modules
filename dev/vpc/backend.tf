# BACKEND

terraform {
  backend "s3" {
    bucket         = "ochirdorj-terraform-kubernetes-backend-bucket"
    key            = "dev/vpc/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "eks-terraform-state-lock"
  }
}