locals {
  ssm_strings = {
    DB_HOST           = aws_db_instance.main.address # host de RDS
    DB_PORT           = tostring(var.db_port)
    DB_USER           = var.db_username
    DB_NAME           = var.db_name
    DB_SSLMODE        = "disable" # cámbialo a "require" si quieres TLS
    JWT_SECRET        = var.jwt_secret
    STORAGE_BASE_PATH = var.storage_base_path
    NFS_SERVER        = aws_instance.nfs.private_ip
    REDIS_ADDR        = "anbapp-redis:6379" # Redis en contenedor Docker
    REDIS_PORT        = "6379"
  }
}

# String parameters
resource "aws_ssm_parameter" "strings" {
  for_each   = local.ssm_strings
  name       = "${var.ssm_path}/${each.key}"
  type       = "String"
  value      = each.value
  overwrite  = true
  depends_on = [aws_db_instance.main, aws_instance.nfs] # asegura que ya exista el endpoint
}

# SecureString para la contraseña
resource "aws_ssm_parameter" "db_password" {
  name      = "${var.ssm_path}/DB_PASSWORD"
  type      = "SecureString"
  value     = var.db_password
  overwrite = true
  # key_id   = "arn:aws:kms:us-east-1:<acct>:key/<cmk-id>"  # solo si quieres CMK propia
}
