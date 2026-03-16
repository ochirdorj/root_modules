module "scp" {
  source = "git::https://github.com/ochirdorj/service_control_policy.git?ref=256f74af8ba83a90595c5e4bfa4ea42d687b162e"

  ##Input variables##
  scp_name = var.scp_name
  scp_description = var.scp_description
  scp_path = "${path.module}/${var.scp_path}"
  scp_type = var.scp_type
  include_root = var.include_root
  target_ou_names = var.target_ou_names
  target_account_names = var.target_account_names
}
