module "scp" {
  source = "git::https://github.com/ochirdorj/service_control_policy.git?ref=1887c19a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e"

  ##Input variables##
  scp_name = "EnforceTag"
  scp_description = "SCP to enforce resource tag"
  scp_json_path = file("../policies/tag_enforce_policy.json")
  scp_type = "SERVICE_CONTROL_POLICY"
  include_root = false
  target_ou_names = ["Security"]
  target_account_names = []
}
