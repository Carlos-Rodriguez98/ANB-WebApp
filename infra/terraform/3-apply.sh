#!/bin/bash
# ==========================================
# Paso 3: Despliegue de infraestructura (Crea los recursos en AWS con Terraform)
# ==========================================

echo -e "\033[36m=== Despliegue de Infraestructura ===\033[0m"

# Verificar conexión con AWS
CRED_FILE="aws_credentials.auto.tfvars"

# Verificar credenciales
if [ ! -f "$CRED_FILE" ]; then
  echo "Error: No se encontraron credenciales ($CRED_FILE)."
  echo "Primero ejecuta: ./1-set-credentials.sh"
  exit 1
fi

echo
echo "Credenciales encontradas. Generando despliegue..."
echo

# Confirmación
read -p "Esto creará recursos en AWS y puede generar costos. ¿Deseas continuar? (si/no): " confirm

if [ "$confirm" != "si" ]; then
  echo -e "\033[33mOperación cancelada.\033[0m"
  exit 0
fi

echo -e "\n\033[36mIniciando despliegue con Terraform...\033[0m"
terraform apply -auto-approve

if [ $? -eq 0 ]; then
  echo -e "\n\033[32mDespliegue completado exitosamente.\033[0m"
  echo -e "\033[33mPuedes ver los outputs con: terraform output\033[0m"
  echo -e "\033[31mPara eliminar toda la infraestructura: ./4-destroy.sh\033[0m"
else
  echo -e "\n\033[31mError durante el despliegue.\033[0m"
  echo -e "\033[33mVerifica los logs de Terraform para más detalles.\033[0m"
  exit 1
fi