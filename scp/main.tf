module "scp" {
  source = "git::https://github.com/ochirdorj/service_control_policy.git?ref=1bb18b9d7478305c03ef57c3e5c63a8a47908515"

  ##Input variables##
  scp_name = var.scp_name
  scp_description = var.scp_description
  scp_path = var.scp_path
  scp_type = var.scp_type
  include_root = var.include_root
  target_ou_names = var.target_ou_names
  target_account_names = var.target_account_names
}
