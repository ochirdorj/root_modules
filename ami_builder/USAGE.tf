# ── HOW TO USE THE AMI OUTPUT IN ANOTHER MODULE ───────────────────────────────
# Once ami_builder runs, reference the AMI ID in your runner module like this:
#
# variable "runner_ami_id" {
#   description = "Pre-baked AMI ID from ami_builder module"
#   type        = string
# }
#
# resource "aws_launch_template" "runner" {
#   name                   = var.launch_template
#   image_id               = var.runner_ami_id
#   instance_type          = var.instance_type
#   update_default_version = true
#
#   iam_instance_profile {
#     name = aws_iam_instance_profile.runner_instance_profile.name
#   }
#
#   tags = merge(local.propagated_tags, {
#     Name = "${local.resource_name_prefix}-launch-template"
#   })
# }
