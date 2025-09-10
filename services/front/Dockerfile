# Dockerfile pour le service front
FROM python:3.11-slim

# Définir le répertoire de travail
WORKDIR /app

# Installer les dépendances Python
RUN pip install requests

# Copier les fichiers de l'application
COPY . .

# Exposer le port par défaut (8000)
EXPOSE 8000

# Donner les permissions d'exécution au script de démarrage
RUN chmod +x start-server.sh

# Commande par défaut pour démarrer le serveur
CMD ["python3", "server.py"]
