#!/bin/bash
set -xe

# Install Docker and utilities
yum update -y || true
amazon-linux-extras install docker -y || yum install -y docker || true
systemctl enable docker
systemctl start docker

# Install docker-compose v2
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
usermod -aG docker ec2-user || true

# Prepare env file
mkdir -p /opt/anbapp && chown ec2-user:ec2-user /opt/anbapp

# Variables pasadas desde Terraform
DB_HOST="${DB_HOST}"
DB_PORT="${DB_PORT}"
DB_USER="${DB_USER}"
DB_PASSWORD="${DB_PASSWORD}"
DB_NAME="${DB_NAME}"
DB_SSLMODE="${DB_SSLMODE}"
JWT_SECRET="${JWT_SECRET}"
STORAGE_BASE_PATH="${STORAGE_BASE_PATH}"
REDIS_ADDR="${REDIS_ADDR}"
REDIS_PORT="${REDIS_PORT}"
NFS_SERVER="${NFS_SERVER}"

cat > /opt/anbapp/.env <<EOF
DB_HOST=$DB_HOST
DB_PORT=$DB_PORT
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASSWORD
DB_NAME=$DB_NAME
DB_SSLMODE=$DB_SSLMODE
JWT_SECRET=$JWT_SECRET
STORAGE_BASE_PATH=$STORAGE_BASE_PATH
REDIS_ADDR=$REDIS_ADDR
REDIS_PORT=$REDIS_PORT
AUTH_SERVER_PORT=8080
VIDEO_SERVER_PORT=8081
VOTING_SERVER_PORT=8082
RANKING_SERVER_PORT=8083
FRONT_SERVER_PORT=8084
EOF

chown ec2-user:ec2-user /opt/anbapp/.env

# Mount NFS for shared storage with retry
mkdir -p "$STORAGE_BASE_PATH"
yum install -y nfs-utils || true

# Retry NFS mount up to 10 times (NFS server might not be ready yet)
echo "Intentando montar NFS desde $NFS_SERVER..."
for i in {1..10}; do
    if mount -t nfs4 "$NFS_SERVER:/srv/nfs/appfiles" "$STORAGE_BASE_PATH"; then
        echo "NFS montado exitosamente"
        break
    else
        echo "Intento $i/10 falló, esperando 30 segundos..."
        sleep 30
    fi
    if [ $i -eq 10 ]; then
        echo "ERROR: No se pudo montar NFS después de 10 intentos"
        exit 1
    fi
done

echo "$NFS_SERVER:/srv/nfs/appfiles $STORAGE_BASE_PATH nfs4 defaults,_netdev 0 0" >> /etc/fstab

# Clone repository and deploy services
yum install -y git || true
cd /opt/anbapp

# Clone repository
echo "Clonando repositorio..."
git clone -b feature/carlos https://github.com/Carlos-Rodriguez98/ANB-WebApp.git repo || {
    echo "Error al clonar repositorio. Verifica la URL y permisos."
    exit 1
}

# Wait for Docker to be fully ready
sleep 10

# Deploy services automatically
echo "Desplegando servicios web..."
cd /opt/anbapp/repo/infra

# Copiar .env al directorio de infra para que docker-compose lo encuentre
cp /opt/anbapp/.env /opt/anbapp/repo/infra/.env

# Export all variables from .env file
set -a
source /opt/anbapp/.env
set +a

docker-compose -f docker-compose.web.yml up -d --build

# Create manual deploy script for future use
cat > /opt/anbapp/deploy.sh <<'DEPLOY_SCRIPT'
#!/bin/bash
set -e
cd /opt/anbapp/repo/infra
cp /opt/anbapp/.env /opt/anbapp/repo/infra/.env
set -a
source /opt/anbapp/.env
set +a
docker-compose -f docker-compose.web.yml up -d --build
DEPLOY_SCRIPT

chmod +x /opt/anbapp/deploy.sh
chown ec2-user:ec2-user /opt/anbapp/deploy.sh

# Instructions
cat > /opt/anbapp/README.txt <<'README'
Los servicios se desplegaron automáticamente al arrancar la instancia.

Para ver el estado:
   docker ps

Para ver logs:
   cd /opt/anbapp/repo/infra
   docker-compose -f docker-compose.web.yml logs -f

Para reiniciar servicios:
   sudo /opt/anbapp/deploy.sh

Para detener servicios:
   cd /opt/anbapp/repo/infra
   docker-compose -f docker-compose.web.yml down

Servicios disponibles:
   - Frontend: http://localhost:8084
   - Auth: http://localhost:8080
   - Video: http://localhost:8081
   - Voting: http://localhost:8082
   - Ranking: http://localhost:8083
README

echo "Despliegue completado. Ver /opt/anbapp/README.txt para más información."
