#!/bin/bash

# Configuration pour AWS
BASE_URL="http://54.234.79.69:8084"

echo "=== Test ANB App sur AWS ==="
echo "URL de base: $BASE_URL"

# 1. Connexion avec un utilisateur existant (depuis init.sql)
echo -e "\n1. Connexion avec Carlos Ramírez..."

LOGIN_RESPONSE=$(curl -s -X POST "$BASE_URL/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "carlos.ramirez@example.com",
    "password": "password123"
  }')

echo "Réponse login: $LOGIN_RESPONSE"

# Extraction du token
TOKEN=$(echo $LOGIN_RESPONSE | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)

if [ -z "$TOKEN" ]; then
    echo "❌ Erreur: Impossible d'obtenir le token d'accès"
    exit 1
fi

echo "✅ Token obtenu: ${TOKEN:0:20}..."

# 2. Upload d'une vidéo de test
echo -e "\n2. Upload d'une vidéo de test..."

# Vérification que le fichier existe
VIDEO_FILE="/home/valentin/Documents/test.mp4"
if [ ! -f "$VIDEO_FILE" ]; then
    echo "❌ Erreur: Fichier vidéo non trouvé: $VIDEO_FILE"
    exit 1
fi

UPLOAD_RESPONSE=$(curl -s -X POST "$BASE_URL/api/videos/upload" \
  -H "Authorization: Bearer $TOKEN" \
  -F "title=Vidéo de test - 5MB" \
  -F "video_file=@$VIDEO_FILE")

echo "Réponse upload: $UPLOAD_RESPONSE"

# Extraction du video_id
VIDEO_ID=$(echo $UPLOAD_RESPONSE | grep -o '"video_id":"[^"]*"' | cut -d'"' -f4)

if [ -z "$VIDEO_ID" ]; then
    echo "❌ Erreur: Impossible d'obtenir l'ID de la vidéo"
    exit 1
fi

echo "✅ Vidéo uploadée avec ID: $VIDEO_ID"

# 3. Vérification du statut de la vidéo
echo -e "\n3. Vérification du statut de la vidéo..."

DETAIL_RESPONSE=$(curl -s -X GET "$BASE_URL/api/videos/$VIDEO_ID" \
  -H "Authorization: Bearer $TOKEN")

echo "Détails de la vidéo: $DETAIL_RESPONSE"

# 4. Publication de la vidéo (une fois qu'elle est prête)
echo -e "\n4. Tentative de publication de la vidéo..."

PUBLISH_RESPONSE=$(curl -s -X POST "$BASE_URL/api/videos/$VIDEO_ID/publish" \
  -H "Authorization: Bearer $TOKEN")

echo "Réponse publication: $PUBLISH_RESPONSE"

# 5. Liste des vidéos de l'utilisateur
echo -e "\n5. Liste des vidéos de l'utilisateur..."

LIST_RESPONSE=$(curl -s -X GET "$BASE_URL/api/videos" \
  -H "Authorization: Bearer $TOKEN")

echo "Liste des vidéos: $LIST_RESPONSE"

echo -e "\n=== Test terminé ==="
