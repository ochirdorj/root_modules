module "scp" {
  source = "git::https://github.com/ochirdorj/service_control_policy.git?ref=1bb18b9d7478305c03ef57c3e5c63a8a47908515"

  ##Input variables##
  scp_name = "EnforceTag"
  scp_description = "SCP to enforce resource tag"
  scp_path = "${path.module}/policies/tag_enforce_policy.json"
  scp_type = "SERVICE_CONTROL_POLICY"
  include_root = false
  target_ou_names = ["Security"]
  target_account_names = []
}
