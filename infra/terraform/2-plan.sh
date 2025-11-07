#!/bin/bash
# ==========================================
# Paso 2: Ver plan de despliegue
# ==========================================

set -euo pipefail

CRED_FILE="aws_credentials.auto.tfvars"

# Verificar credenciales
if [ ! -f "$CRED_FILE" ]; then
  echo
  echo "Error: No se encontraron credenciales ($CRED_FILE)."
  echo "Primero ejecuta: ./1-set-credentials.sh"
  exit 1
fi

echo
echo "Credenciales encontradas. Generando plan de despliegue..."
echo

# Comprobar que terraform esté disponible
if ! command -v terraform >/dev/null 2>&1; then
  echo "Error: terraform no está instalado o no está en PATH."
  exit 1
fi

# Ejecutar plan (NO crea recursos)
terraform plan
PLAN_RC=$?

if [ "$PLAN_RC" -eq 0 ]; then
  echo
  echo "PLAN GENERADO EXITOSAMENTE"
  echo "Revisa el plan arriba para ver qué recursos se crearán."
  echo "Si todo se ve bien, ejecuta: ./3-apply.sh"
  echo
else
  echo
  echo "Error al generar el plan (terraform plan devolvió código $PLAN_RC)."
  echo "Posibles causas: credenciales expiradas o error en la configuración de Terraform."
  exit "$PLAN_RC"
fi