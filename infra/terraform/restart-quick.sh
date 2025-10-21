#!/bin/bash
# Script pour mettre à jour le code rapidement sans redéployer l'infrastructure

# Source les credentials AWS
source ./1-set-credentials.sh

# Récupère l'IP de l'instance web
WEB_IP=$(terraform output -raw web_instance_public_ip 2>/dev/null)

if [ -z "$WEB_IP" ]; then
    echo "❌ Impossible de récupérer l'IP de l'instance web"
    exit 1
fi

echo "🔄 Mise à jour du code sur l'instance web ($WEB_IP)..."

# Commandes à exécuter sur l'instance
UPDATE_SCRIPT='
cd /opt/anbapp/repo
echo "📥 Récupération des dernières modifications..."
git pull origin dev

echo "🐳 Reconstruction et redémarrage des conteneurs..."
cd /opt/anbapp/repo/infra
cp /opt/anbapp/.env ./.env

# Export des variables d'\''environnement
set -a
source .env
set +a

# Redémarrage avec reconstruction
/usr/local/bin/docker-compose -f docker-compose.web.yml down
/usr/local/bin/docker-compose -f docker-compose.web.yml up -d --build

echo "✅ Mise à jour terminée!"
echo "🌐 Services disponibles sur:"
echo "   - Frontend: http://localhost:8084"
echo "   - Auth: http://localhost:8080"
echo "   - Video: http://localhost:8081"
echo "   - Voting: http://localhost:8082"
echo "   - Ranking: http://localhost:8083"
'

# Exécution sur l'instance via SSH
ssh -i ~/.ssh/anbapp-keypair.pem -o StrictHostKeyChecking=no ec2-user@$WEB_IP "$UPDATE_SCRIPT"

if [ $? -eq 0 ]; then
    echo "✅ Code mis à jour avec succès sur $WEB_IP"
    echo "🌐 Votre application est accessible sur http://$WEB_IP:8084"
else
    echo "❌ Erreur lors de la mise à jour du code"
    exit 1
fi
