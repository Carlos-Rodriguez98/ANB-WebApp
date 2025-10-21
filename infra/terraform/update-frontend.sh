#!/bin/bash
# Script pour mettre à jour uniquement le frontend (plus rapide)

# Source les credentials AWS
source ./1-set-credentials.sh

# Récupère l'IP de l'instance web
WEB_IP=$(terraform output -raw web_instance_public_ip 2>/dev/null)

if [ -z "$WEB_IP" ]; then
    echo "❌ Impossible de récupérer l'IP de l'instance web"
    exit 1
fi

echo "🎨 Mise à jour du frontend sur l'instance web ($WEB_IP)..."

# Commandes à exécuter sur l'instance
UPDATE_FRONTEND_SCRIPT='
cd /opt/anbapp/repo
echo "📥 Récupération des dernières modifications..."
git pull origin dev

echo "🎨 Redémarrage uniquement du service frontend..."
cd /opt/anbapp/repo/infra

# Export des variables d'\''environnement
set -a
source /opt/anbapp/.env
set +a

# Redémarrage seulement du frontend
/usr/local/bin/docker-compose -f docker-compose.web.yml stop front
/usr/local/bin/docker-compose -f docker-compose.web.yml up -d --build front

echo "✅ Frontend mis à jour!"
echo "🌐 Frontend accessible sur: http://localhost:8084"
'

# Exécution sur l'instance via SSH
ssh -i ~/.ssh/anbapp-keypair.pem -o StrictHostKeyChecking=no ec2-user@$WEB_IP "$UPDATE_FRONTEND_SCRIPT"

if [ $? -eq 0 ]; then
    echo "✅ Frontend mis à jour avec succès sur $WEB_IP"
    echo "🌐 Votre application est accessible sur http://$WEB_IP:8084"
else
    echo "❌ Erreur lors de la mise à jour du frontend"
    exit 1
fi
