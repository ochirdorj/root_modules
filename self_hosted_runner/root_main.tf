module "self_hosted" {
  source = "git::https://github.com/ochirdorj/self_hosted_runner.git?ref=e129dc9dab9b9fc789b9a53fff94ec1efcf87bc7"

  #Input variables
  lambda_zip_path                    = "${path.module}/function.zip"
  instance_type                      = var.instance_type
  Environment                        = var.Environment
  Managed_by                         = var.Managed_by
  Project                            = var.Project
  Team                               = var.Team
  Owner                              = var.Owner
  root_volume_size                   = var.root_volume_size
  vpc_id                             = var.vpc_id
  lambda_subnets                     = var.lambda_subnets
  github_app_credentials_secret_name = var.github_app_credentials_secret_name
  runner_labels                      = var.runner_labels
  launch_template                    = var.launch_template
  create_spot_role                   = var.create_spot_role
  stage_name                         = var.stage_name
  kms_key_arn                        = var.kms_key_arn
  image_id                           = var.image_id
  webhook_lambda_zip_path            = var.webhook_lambda_zip_path
  webhook_secret_key                 = var.webhook_secret_key
}