#!/bin/bash
# ========================================
# Paso 4: Eliminar infraestructura
# ========================================

echo -e "\e[31m========================================\e[0m"
echo -e "\e[31mDESTRUCCIÓN DE INFRAESTRUCTURA\e[0m"
echo -e "\e[31m========================================\e[0m"
echo ""

# Verificar que existan las credenciales
CRED_FILE="aws_credentials.auto.tfvars"
if [ ! -f "$CRED_FILE" ]; then
    echo -e "\e[31mError: No se encontraron credenciales\e[0m"
    echo ""
    echo -e "\e[33mPrimero ejecuta: ./1-set-credentials.sh\e[0m"
    echo ""
    exit 1
fi

echo -e "\e[33mEste script ELIMINARÁ PERMANENTEMENTE:\e[0m"
echo "  - Todas las instancias EC2"
echo "  - La base de datos RDS (y sus datos)"
echo "  - VPC, Subnets, Security Groups"
echo "  - NAT Gateway"
echo ""
echo -e "\e[31mESTA ACCIÓN NO SE PUEDE DESHACER\e[0m"
echo ""

read -p "¿Estás SEGURO? (escribe 'ELIMINAR' en mayúsculas): " confirm

if [ "$confirm" != "ELIMINAR" ]; then
    echo ""
    echo -e "\e[32mOperación cancelada\e[0m"
    exit 0
fi

echo ""
echo -e "\e[31mEjecutando terraform destroy...\e[0m"
echo -e "\e[33mEsto puede tomar varios minutos...\e[0m"
echo ""

terraform destroy -auto-approve
EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
    echo ""
    echo -e "\e[32m========================================\e[0m"
    echo -e "\e[32mINFRAESTRUCTURA ELIMINADA EXITOSAMENTE\e[0m"
    echo -e "\e[32m========================================\e[0m"
    echo ""
    echo "Todos los recursos han sido eliminados de AWS"
    echo -e "\e[32mYa no se generarán costos por estos recursos\e[0m"
    echo ""

    # Limpiar archivo de credenciales
    echo -e "\e[33mLimpiando archivo de credenciales...\e[0m"
    rm -f "$CRED_FILE"
    echo -e "\e[32mArchivo de credenciales eliminado\e[0m"
    echo ""
else
    echo ""
    echo -e "\e[31m========================================\e[0m"
    echo -e "\e[31mERROR AL ELIMINAR RECURSOS\e[0m"
    echo -e "\e[31m========================================\e[0m"
    echo ""
    echo -e "\e[33mAlgunos recursos pueden no haberse eliminado\e[0m"
    echo -e "\e[33mVerifica manualmente en la consola de AWS\e[0m"
    echo ""
    echo -e "\e[33mPosibles causas:\e[0m"
    echo "  - Recursos con dependencias activas"
    echo "  - Credenciales expiradas (ejecuta: ./1-set-credentials.sh)"
    echo ""
    exit 1
fi
