locals {
  ssm_strings = {
    DB_HOST        = aws_db_instance.main.address # host de RDS
    DB_PORT        = tostring(var.db_port)
    DB_USER        = var.db_username
    DB_NAME        = var.db_name
    DB_SSLMODE     = "require"
    JWT_SECRET     = var.jwt_secret
    S3_BUCKET_NAME = aws_s3_bucket.storage.id
    AWS_REGION     = var.aws_region
    STORAGE_MODE   = "s3"
    REDIS_ADDR     = "anbapp-redis:6379"
    REDIS_PORT     = "6379"
  }
}

# String parameters
resource "aws_ssm_parameter" "strings" {
  for_each   = local.ssm_strings
  name       = "${var.ssm_path}/${each.key}"
  type       = "String"
  value      = each.value
  overwrite  = true
  depends_on = [aws_db_instance.main, aws_s3_bucket.storage]
}

# SecureString para la contraseña
resource "aws_ssm_parameter" "db_password" {
  name      = "${var.ssm_path}/DB_PASSWORD"
  type      = "SecureString"
  value     = var.db_password
  overwrite = true
}
