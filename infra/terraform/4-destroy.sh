#!/bin/bash

# Script 4: Destroy Infrastructure
echo "=== Terraform Destroy ==="
echo "⚠️  ATTENTION: Ceci va SUPPRIMER toute votre infrastructure AWS !"
echo ""

read -p "Êtes-vous sûr de vouloir détruire l'infrastructure ? (oui/non): " confirm

if [ "$confirm" = "oui" ] || [ "$confirm" = "yes" ]; then
    echo "🗑️  Destruction de l'infrastructure..."
    terraform destroy -auto-approve
    
    if [ $? -eq 0 ]; then
        echo "✅ Infrastructure détruite avec succès"
    else
        echo "❌ Erreur lors de la destruction"
    fi
else
    echo "❌ Opération annulée"
fi
