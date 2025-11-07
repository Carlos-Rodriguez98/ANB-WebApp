# OPCIÓN A: Usar el key pair existente en AWS Academy (vockey) - MÁS SIMPLE
data "aws_key_pair" "main" {
  key_name = "vockey"
}

# OPCIÓN B: Crear un nuevo key pair desde labsuser.pub
# Descomenta esto si prefieres crear uno nuevo:
# resource "aws_key_pair" "main" {
#   key_name   = "${var.project_name}-key"
#   public_key = file(pathexpand("~/.ssh/labsuser.pub"))
# }
# 
# Y comenta la OPCIÓN A arriba
