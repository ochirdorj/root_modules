terraform {
  backend "s3" {
    bucket = "ochirdorj-terraform-backend-bucket"
    key = "infra/vpc_backend/terraform.tfstate"
    region = "us-east-1"
    encrypt = true
  }
}