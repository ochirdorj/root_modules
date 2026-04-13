# REMOTE STATE — EKS

data "terraform_remote_state" "eks" {
  backend = "s3"
  config = {
    bucket = "ochirdorj-terraform-kubernetes-backend-bucket"
    key    = "dev/eks/terraform.tfstate"
    region = "us-east-1"
  }
}

# MONITORING — PROMETHEUS + GRAFANA

module "monitoring" {
  source = "git::https://github.com/ochirdorj/infra-core-observability-monitoring-template.git?ref=91577b0ad99c103ff339b7c2d2b5cb7424911135"

  namespace              = var.namespace
  grafana_admin_password = var.grafana_admin_password
  prometheus_retention   = var.prometheus_retention
}