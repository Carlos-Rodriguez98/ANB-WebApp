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

# AWS CLI
dnf install -y awscli || yum install -y awscli || true

SSM_BASE_PATH="${SSM_BASE_PATH:-/anbapp}"

fetch_param() {
  local name="$1"
  local decrypt="$2"
  if [ "$decrypt" = "true" ]; then
    aws ssm get-parameter --name "$name" --with-decryption --query 'Parameter.Value' --output text
  else
    aws ssm get-parameter --name "$name" --query 'Parameter.Value' --output text
  fi
}

# Prepare env file
mkdir -p /opt/anbapp && chown ec2-user:ec2-user /opt/anbapp

DB_HOST=$(fetch_param "$SSM_BASE_PATH/DB_HOST" false)
DB_PORT=$(fetch_param "$SSM_BASE_PATH/DB_PORT" false)
DB_USER=$(fetch_param "$SSM_BASE_PATH/DB_USER" false)
DB_PASSWORD=$(fetch_param "$SSM_BASE_PATH/DB_PASSWORD" true)
DB_NAME=$(fetch_param "$SSM_BASE_PATH/DB_NAME" false)
DB_SSLMODE=$(fetch_param "$SSM_BASE_PATH/DB_SSLMODE" false)
JWT_SECRET=$(fetch_param "$SSM_BASE_PATH/JWT_SECRET" false)
STORAGE_BASE_PATH=$(fetch_param "$SSM_BASE_PATH/STORAGE_BASE_PATH" false)
REDIS_ADDR=$(fetch_param "$SSM_BASE_PATH/REDIS_ADDR" false)
REDIS_PORT=$(fetch_param "$SSM_BASE_PATH/REDIS_PORT" false)
NFS_SERVER=$(fetch_param "$SSM_BASE_PATH/NFS_SERVER" false)

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
WORKER_CONCURRENCY=2
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

# Clone repository and deploy worker service
yum install -y git || true
cd /opt/anbapp

# Clone repository
echo "Clonando repositorio..."
git clone https://github.com/Carlos-Rodriguez98/ANB-WebApp.git repo || {
    echo "Error al clonar repositorio. Verifica la URL y permisos."
    exit 1
}

# Wait for Docker to be fully ready
sleep 10

# Deploy worker service automatically
echo "Desplegando worker de procesamiento de video..."
cd /opt/anbapp/repo/infra
source /opt/anbapp/.env
docker-compose -f docker-compose.worker.yml up -d --build

# Create manual deploy script for future use
cat > /opt/anbapp/deploy.sh <<'DEPLOY_SCRIPT'
#!/bin/bash
set -e
cd /opt/anbapp/repo/infra
source /opt/anbapp/.env
docker-compose -f docker-compose.worker.yml up -d --build
DEPLOY_SCRIPT

chmod +x /opt/anbapp/deploy.sh
chown ec2-user:ec2-user /opt/anbapp/deploy.sh

cat > /opt/anbapp/README.txt <<'README'
El worker de procesamiento de video se desplegó automáticamente al arrancar la instancia.

Para ver el estado:
   docker ps

Para ver logs del worker:
   cd /opt/anbapp/repo/infra
   docker-compose -f docker-compose.worker.yml logs -f processing-service

Para reiniciar el worker:
   sudo /opt/anbapp/deploy.sh

Para detener el worker:
   cd /opt/anbapp/repo/infra
   docker-compose -f docker-compose.worker.yml down

Este worker procesa videos de forma aislada en una instancia privada dedicada.
README

echo "Despliegue del worker completado. Ver /opt/anbapp/README.txt para más información."
