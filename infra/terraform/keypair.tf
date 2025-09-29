resource "aws_key_pair" "main" {
  key_name   = "${var.project_name}-key"
  public_key = file(pathexpand("~/.ssh/anbapp_key.pub"))
}
