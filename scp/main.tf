module "scp" {
  source = "git::https://github.com/ochirdorj/service_control_policy.git?ref=50596c10dd826cbc0cddb5ef194dfa7a0e6a0b6d"

  ##Input variables##
  scp_name = var.scp_name
  scp_description = var.scp_description
  scp_path = "${path.module}/policies/tag_enforce_policy.json"
  scp_type = var.scp_type
  include_root = var.include_root
  target_ou_names = var.target_ou_names
  target_account_names = var.target_account_names
}
