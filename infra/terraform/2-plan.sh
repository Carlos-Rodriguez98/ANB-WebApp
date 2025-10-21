#!/bin/bash

# Script 2: Plan Terraform
echo "=== Terraform Plan ==="

# Vérifier si terraform.tfvars existe
if [ ! -f terraform.tfvars ]; then
    echo "❌ Erreur: terraform.tfvars non trouvé"
    echo "Exécutez d'abord: ./1-set-credentials.sh"
    exit 1
fi

# Initialiser Terraform
echo "📦 Initialisation de Terraform..."
terraform init

# Plannifier le déploiement
echo "📋 Génération du plan de déploiement..."
terraform plan

echo ""
echo "✅ Plan généré avec succès"
echo "Prochaine étape: ./3-apply.sh"
