provider "aws" {
  region = var.aws_region

  # Para AWS Academy: forzar lectura de variables de entorno
  access_key = var.aws_access_key_id
  secret_key = var.aws_secret_access_key
  token      = var.aws_session_token
}