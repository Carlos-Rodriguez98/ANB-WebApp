#!/bin/bash
set -xe

# Actualiza e instala Docker
yum update -y
amazon-linux-extras install docker -y
systemctl enable docker
systemctl start docker

# Instala docker-compose v2
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Ajusta permisos
usermod -aG docker ec2-user

dnf install -y awscli || yum install -y awscli || true

SSM_BASE_PATH="${SSM_BASE_PATH:-/anbapp}"

fetch_param() {
  local name="$1"
  local decrypt="$2"  # "true" para secretos
  if [ "$decrypt" = "true" ]; then
    aws ssm get-parameter --name "$name" --with-decryption --query 'Parameter.Value' --output text
  else
    aws ssm get-parameter --name "$name" --query 'Parameter.Value' --output text
  fi
}

mkdir -p /opt/anbapp && chown ec2-user:ec2-user /opt/anbapp

cat > /opt/anbapp/.env <<EOF
DB_HOST=$(fetch_param "$SSM_BASE_PATH/DB_HOST" false)
DB_PORT=$(fetch_param "$SSM_BASE_PATH/DB_PORT" false)
DB_USER=$(fetch_param "$SSM_BASE_PATH/DB_USER" false)
DB_PASSWORD=$(fetch_param "$SSM_BASE_PATH/DB_PASSWORD" true)
DB_NAME=$(fetch_param "$SSM_BASE_PATH/DB_NAME" false)
DB_SSLMODE=$(fetch_param "$SSM_BASE_PATH/DB_SSLMODE" false)

JWT_SECRET=$(fetch_param "$SSM_BASE_PATH/JWT_SECRET" false)
STORAGE_BASE_PATH=$(fetch_param "$SSM_BASE_PATH/STORAGE_BASE_PATH" false)

AUTH_SERVER_PORT=8080
VIDEO_SERVER_PORT=8081
VOTING_SERVER_PORT=8082
RANKING_SERVER_PORT=8083
FRONT_SERVER_PORT=8084
EOF

chown ec2-user:ec2-user /opt/anbapp/.env