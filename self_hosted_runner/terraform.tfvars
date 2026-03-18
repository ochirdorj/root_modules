# ─── Tags ─────────────────────────────────────────────────────────────────────
# Environment = "sandbox"
# Managed_by  = "terraform"
# Project     = "project-13"
# Team        = "ap13"
# Owner       = "Tugsuu"

# ─── EC2 ──────────────────────────────────────────────────────────────────────
# instance_type    = ["t3.medium", "c5.large", "c6i.large"]
# root_volume_size = 20
# image_id         = "ami-01f3bee89838bc457"

# ─── Network ──────────────────────────────────────────────────────────────────
# vpc_id         = "vpc-0cbbdf4c84f9c79dd"
# lambda_subnets = ["subnet-01f55f939b6b4de8d", "subnet-07ef815e17eb4894a"]

# ─── GitHub ───────────────────────────────────────────────────────────────────
# github_app_credentials_secret_name = "self_hosted_runner"
# runner_labels                      = "self-hosted, linux, x64"

# ─── Lambda ───────────────────────────────────────────────────────────────────
# lambda_zip_path         = "${path.module}/function.zip"
# webhook_lambda_zip_path = "${path.module}/webhook_validator.zip"
# webhook_secret_key      = "webhook_secret"

# ─── Launch Template ──────────────────────────────────────────────────────────
# launch_template = "github-runner-lt"

# ─── API Gateway ──────────────────────────────────────────────────────────────
# stage_name = "dev"

# ─── IAM ──────────────────────────────────────────────────────────────────────
# create_spot_role = true

# ─── KMS (optional) ───────────────────────────────────────────────────────────
# kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/your-key-id"
