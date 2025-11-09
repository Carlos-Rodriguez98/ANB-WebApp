#!/bin/bash
set -xe

# Install Docker and utilities (Amazon Linux 2023)
yum update -y || true
yum install -y docker || true
systemctl enable docker
systemctl start docker

# Install docker-compose v2 (standalone)
DOCKER_COMPOSE_VERSION="2.23.0"
curl -L "https://github.com/docker/compose/releases/download/v$${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Verify docker-compose installation
/usr/local/bin/docker-compose version || echo "Warning: docker-compose installation may have issues"

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
S3_BUCKET_NAME="${S3_BUCKET_NAME}"
AWS_REGION="${AWS_REGION}"
SQS_QUEUE_URL="${SQS_QUEUE_URL}"

cat > /opt/anbapp/.env <<EOF
DB_HOST=$DB_HOST
DB_PORT=$DB_PORT
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASSWORD
DB_NAME=$DB_NAME
DB_SSLMODE=$DB_SSLMODE
JWT_SECRET=$JWT_SECRET
S3_BUCKET_NAME=$S3_BUCKET_NAME
AWS_REGION=$AWS_REGION
STORAGE_MODE=s3
SQS_QUEUE_URL=$SQS_QUEUE_URL
AUTH_SERVER_PORT=8080
VIDEO_SERVER_PORT=8081
VOTING_SERVER_PORT=8082
RANKING_SERVER_PORT=8083
FRONT_SERVER_PORT=8084
EOF

chown ec2-user:ec2-user /opt/anbapp/.env

# Instalar AWS CLI si no está instalado
yum install -y aws-cli || true

#Configurar región para AWS CLI
aws configure set region ${AWS_REGION}

# Verificar acceso a S3
echo "Verificando acceso a bucket S3..."
aws s3 ls s3://${S3_BUCKET_NAME}/ || echo "Bucket vacío o primer acceso"

# Clone repository and deploy worker service
yum install -y git || true
cd /opt/anbapp

# Clone repository
echo "Clonando repositorio..."
git clone -b feature/carlos-entrega3 https://github.com/Carlos-Rodriguez98/ANB-WebApp.git repo || {
    echo "Error al clonar repositorio. Verifica la URL y permisos."
    exit 1
}

# Wait for Docker to be fully ready
sleep 10

# Deploy worker service automatically
echo "Desplegando worker de procesamiento de video..."
cd /opt/anbapp/repo/infra

# Copiar .env al directorio de infra para que docker-compose lo encuentre
cp /opt/anbapp/.env /opt/anbapp/repo/infra/.env

# Export all variables from .env file
set -a
source /opt/anbapp/.env
set +a

/usr/local/bin/docker-compose -f docker-compose.worker.yml up -d --build

# Create manual deploy script for future use
cat > /opt/anbapp/deploy.sh <<'DEPLOY_SCRIPT'
#!/bin/bash
set -e
cd /opt/anbapp/repo/infra
cp /opt/anbapp/.env /opt/anbapp/repo/infra/.env
set -a
source /opt/anbapp/.env
set +a
/usr/local/bin/docker-compose -f docker-compose.worker.yml up -d --build
DEPLOY_SCRIPT

chmod +x /opt/anbapp/deploy.sh
chown ec2-user:ec2-user /opt/anbapp/deploy.sh

cat > /opt/anbapp/README.txt <<'README'
El worker de procesamiento de video se desplegó automáticamente al arrancar la instancia.

Para ver el estado:
   docker ps

Para ver logs del worker:
   cd /opt/anbapp/repo/infra
   /usr/local/bin/docker-compose -f docker-compose.worker.yml logs -f processing-service

Para reiniciar el worker:
   sudo /opt/anbapp/deploy.sh

Para detener el worker:
   cd /opt/anbapp/repo/infra
   /usr/local/bin/docker-compose -f docker-compose.worker.yml down

Este worker procesa videos de forma aislada en una instancia privada dedicada.
README

echo "Despliegue del worker completado. Ver /opt/anbapp/README.txt para más información."
