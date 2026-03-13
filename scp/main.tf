module "scp" {
  source = "git::https://github.com/ochirdorj/service_control_policy.git?ref=1887c1948c1e46c69ff9eee744aa8c5c8f98c510"

  ##Input variables##
  scp_name = "EnforceTag"
  scp_description = "SCP to enforce resource tag"
  scp_path = "${path.module}/policies/tag_enforce_policy.json"
  scp_type = "SERVICE_CONTROL_POLICY"
  include_root = false
  target_ou_names = ["Security"]
  target_account_names = []
}
