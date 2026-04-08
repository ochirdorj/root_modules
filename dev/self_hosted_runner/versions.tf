terraform {
  required_version = "~> 1.13.0"
  required_providers {
    aws = {
      version = "~> 6.10.0"
      source  = "hashicorp/aws"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9"
    }
  }
}