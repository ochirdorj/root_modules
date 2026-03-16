module "scp" {
  source = "git::https://github.com/ochirdorj/service_control_policy.git?ref=81989452ad02538066b54f32ae9f947978755d60"

  ##Input variables##
  scp_name = var.scp_name
  scp_description = var.scp_description
  scp_path = "${path.module}/${var.scp_path}"
  scp_type = var.scp_type
  include_root = var.include_root
  target_ou_names = var.target_ou_names
  target_account_names = var.target_account_names
}
