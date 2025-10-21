#!/bin/bash

# Script pour configurer les credentials AWS Academy sur Linux
# Équivalent du script PowerShell 1-set-credentials.ps1

echo "=== Configuration des Credentials AWS Academy ==="
echo ""
echo "INSTRUCTIONS:"
echo "1. Allez sur AWS Academy -> Learner Lab"
echo "2. Assurez-vous que le lab soit DÉMARRÉ (cercle vert)"
echo "3. Cliquez sur 'AWS Details' -> 'Show'"
echo "4. Copiez CHAQUE credential COMPLÈTE (sans espaces)"
echo ""

# Demander les credentials
read -p "AWS_ACCESS_KEY_ID (commence par ASIA...): " AWS_ACCESS_KEY_ID
read -p "AWS_SECRET_ACCESS_KEY: " AWS_SECRET_ACCESS_KEY
read -p "AWS_SESSION_TOKEN: " AWS_SESSION_TOKEN

# Créer le fichier terraform.tfvars
cat > terraform.tfvars << EOF
# Credentials AWS (généré automatiquement)
aws_access_key_id     = "$AWS_ACCESS_KEY_ID"
aws_secret_access_key = "$AWS_SECRET_ACCESS_KEY"
aws_session_token     = "$AWS_SESSION_TOKEN"

# Configuration de la base de données
db_password = "SecurePassword123!"

# Votre IP publique pour SSH (remplacez par votre IP)
allowed_ssh_cidr = "0.0.0.0/0"

# Configuration des ports
front_server_port = 5000
EOF

echo ""
echo "✅ Credentials configurés dans terraform.tfvars"
echo "⚠️  IMPORTANT: Remplacez 'allowed_ssh_cidr' par votre IP publique pour la sécurité"
echo ""
echo "Prochaines étapes:"
echo "1. ./2-plan.sh"
echo "2. ./3-apply.sh"
