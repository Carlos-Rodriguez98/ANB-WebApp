#!/bin/bash

# Script 3: Apply Terraform
echo "=== Terraform Apply ==="

# Vérifier si terraform.tfvars existe
if [ ! -f terraform.tfvars ]; then
    echo "❌ Erreur: terraform.tfvars non trouvé"
    echo "Exécutez d'abord: ./1-set-credentials.sh"
    exit 1
fi

echo "🚀 Déploiement de l'infrastructure AWS..."
echo "⚠️  Cette opération peut prendre 10-15 minutes"
echo ""

# Appliquer la configuration
terraform apply -auto-approve

if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 Déploiement réussi !"
    echo ""
    echo "📊 Informations importantes:"
    terraform output
    echo ""
    echo "🌐 Votre application sera accessible via l'IP publique affichée ci-dessus"
    echo "📝 Sauvegardez ces informations !"
else
    echo "❌ Erreur lors du déploiement"
    exit 1
fi
