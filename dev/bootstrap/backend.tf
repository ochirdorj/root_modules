terraform {
  backend "s3" {
    bucket  = "ochirdorj-terraform-kubernetes-backend-bucket"
    key     = "dev/bootstrap/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}