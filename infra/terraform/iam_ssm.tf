# iam_ssm.tf
data "aws_caller_identity" "current" {}

# Rol que asumen las instancias EC2
data "aws_iam_policy_document" "ec2_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "anbapp_ssm_role" {
  name               = "${var.project_name}-ssm-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_trust.json
}

# Habilita SSM Agent / Session Manager
resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.anbapp_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Política mínima: las EC2 solo LEEN parámetros bajo ${var.ssm_path}/*
data "aws_iam_policy_document" "ssm_read_params" {
  statement {
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParametersByPath"
    ]
    resources = [
      "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter${var.ssm_path}/*"
    ]
  }
}

resource "aws_iam_policy" "ssm_read_params" {
  name   = "${var.project_name}-read-ssm-params"
  policy = data.aws_iam_policy_document.ssm_read_params.json
}

resource "aws_iam_role_policy_attachment" "attach_read_params" {
  role       = aws_iam_role.anbapp_ssm_role.name
  policy_arn = aws_iam_policy.ssm_read_params.arn
}

# Instance profile para asociar a las EC2
resource "aws_iam_instance_profile" "anbapp_ssm_profile" {
  name = "${var.project_name}-ssm-profile"
  role = aws_iam_role.anbapp_ssm_role.name
}
