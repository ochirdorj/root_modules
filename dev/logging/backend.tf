# BACKEND

terraform {
  backend "s3" {
    bucket         = "ochirdorj-terraform-kubernetes-backend-bucket"
    key            = "dev/logging/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "eks-terraform-state-lock"
  }
}