#!/bin/bash
# ==========================================
# Paso 1: Configurar credenciales temporales de AWS Academy
# ==========================================

set -e

echo
echo "=== Configuración de credenciales AWS ==="

read -p "AWS_ACCESS_KEY_ID: " AWS_ACCESS_KEY_ID
read -p "AWS_SECRET_ACCESS_KEY: " AWS_SECRET_ACCESS_KEY
read -p "AWS_SESSION_TOKEN: " AWS_SESSION_TOKEN

# Guardar en archivo temporal (Terraform lo usará automáticamente)
cat > aws_credentials.auto.tfvars <<EOF
aws_access_key_id     = "$AWS_ACCESS_KEY_ID"
aws_secret_access_key = "$AWS_SECRET_ACCESS_KEY"
aws_session_token     = "$AWS_SESSION_TOKEN"
EOF

# Exportar variables de entorno
export AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID"
export AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY"
export AWS_SESSION_TOKEN="$AWS_SESSION_TOKEN"
export AWS_DEFAULT_REGION="us-east-1"

echo ""
echo "Verificando conexión con AWS..."
if aws sts get-caller-identity --output json >/dev/null 2>&1; then
  echo "Credenciales válidas y conexión exitosa."
else
  echo "Error al conectar con AWS. Revisa las credenciales o el estado del lab."
  exit 1
fi