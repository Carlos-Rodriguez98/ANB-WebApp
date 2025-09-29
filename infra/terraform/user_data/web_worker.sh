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
