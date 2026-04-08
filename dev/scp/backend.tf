terraform {
  backend "s3" {
    bucket  = "ochirdorj-terraform-backend-bucket"
    key     = "infra/scp_tag_enforcement/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}