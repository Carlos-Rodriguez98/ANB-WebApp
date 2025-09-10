#!/bin/bash
# Script de démarrage rapide pour le serveur de développement

echo "🚀 Démarrage du serveur ANB Rising Stars..."
echo ""

# Aller dans le répertoire front
cd "$(dirname "$0")"

# Vérifier si Python3 est disponible
if command -v python3 &> /dev/null; then
    python3 server.py $@
elif command -v python &> /dev/null; then
    python server.py $@
else
    echo "❌ Python n'est pas installé sur ce système"
    echo "   Veuillez installer Python 3 pour utiliser ce serveur"
    exit 1
fi
