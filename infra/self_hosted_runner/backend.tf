terraform {
  backend "s3" {
    bucket  = "ochirdorj-terraform-backend-bucket"
    key     = "infra/self_hosted_runner/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}