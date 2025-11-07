# iam_ssm.tf
data "aws_caller_identity" "current" {}

# Para AWS Academy: usar el LabRole existente
data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

# Instance profile usando LabRole (ya existe en AWS Academy)
data "aws_iam_instance_profile" "lab_instance_profile" {
  name = "LabInstanceProfile"
}

# Output para usar en EC2
output "lab_instance_profile_name" {
  value = data.aws_iam_instance_profile.lab_instance_profile.name
}