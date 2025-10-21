#!/bin/bash
# Script pour redémarrer complètement les services (sans git pull)

# Source les credentials AWS
source ./1-set-credentials.sh

# Récupère l'IP de l'instance web
WEB_IP=$(terraform output -raw web_instance_public_ip 2>/dev/null)

if [ -z "$WEB_IP" ]; then
    echo "❌ Impossible de récupérer l'IP de l'instance web"
    exit 1
fi

echo "🔄 Redémarrage complet des services sur l'instance web ($WEB_IP)..."

# Commandes à exécuter sur l'instance
RESTART_SCRIPT='
cd /opt/anbapp/repo/infra

echo "🛑 Arrêt des conteneurs..."
/usr/local/bin/docker-compose -f docker-compose.web.yml down

echo "🧹 Nettoyage des images..."
docker system prune -f

echo "🐳 Reconstruction complète et redémarrage..."
cp /opt/anbapp/.env ./.env

# Export des variables d'\''environnement
set -a
source .env
set +a

/usr/local/bin/docker-compose -f docker-compose.web.yml up -d --build --force-recreate

echo "✅ Redémarrage complet terminé!"
docker ps
'

# Exécution sur l'instance via SSH
ssh -i ~/.ssh/anbapp-keypair.pem -o StrictHostKeyChecking=no ec2-user@$WEB_IP "$RESTART_SCRIPT"

if [ $? -eq 0 ]; then
    echo "✅ Services redémarrés avec succès sur $WEB_IP"
    echo "🌐 Votre application est accessible sur http://$WEB_IP:8084"
else
    echo "❌ Erreur lors du redémarrage des services"
    exit 1
fi
