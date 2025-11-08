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

# Habilitar e iniciar rpcbind (necesario para clientes NFS)
systemctl enable rpcbind
systemctl start rpcbind

# Verificar conectividad con el servidor NFS antes de intentar montar
echo "Verificando conectividad con servidor NFS $NFS_SERVER..."
for i in {1..15}; do
    if ping -c 1 -W 2 "$NFS_SERVER" > /dev/null 2>&1; then
        echo "Servidor NFS alcanzable"
        break
    else
        echo "Intento $i/15: Servidor NFS no alcanzable, esperando 20 segundos..."
        sleep 20
    fi
    if [ $i -eq 15 ]; then
        echo "ERROR: No se puede alcanzar el servidor NFS"
        exit 1
    fi
done

# Verificar que el servidor NFS tenga el export disponible
echo "Verificando exports disponibles en $NFS_SERVER..."
for i in {1..10}; do
    if showmount -e "$NFS_SERVER" > /dev/null 2>&1; then
        echo "Exports NFS disponibles:"
        showmount -e "$NFS_SERVER"
        break
    else
        echo "Intento $i/10: Exports no disponibles aún, esperando 30 segundos..."
        sleep 30
    fi
    if [ $i -eq 10 ]; then
        echo "WARNING: No se pudieron verificar exports, intentando montar de todos modos..."
    fi
done

# Retry NFS mount up to 10 times
echo "Intentando montar NFS desde $NFS_SERVER..."
for i in {1..10}; do
    if mount -t nfs4 -o rw,hard,intr,rsize=8192,wsize=8192 "$NFS_SERVER:/srv/nfs/appfiles" "$STORAGE_BASE_PATH"; then
        echo "NFS montado exitosamente"
        break
    else
        echo "Intento $i/10 falló, esperando 30 segundos..."
        sleep 30
    fi
    if [ $i -eq 10 ]; then
        echo "ERROR: No se pudo montar NFS después de 10 intentos"
        echo "Detalles de red:"
        ip addr
        echo "Rutas:"
        ip route
        echo "Logs del sistema:"
        journalctl -u nfs-client.target -n 50 --no-pager
        exit 1
    fi
done

# Verificar que el montaje esté activo
df -h | grep "$STORAGE_BASE_PATH"
ls -la "$STORAGE_BASE_PATH"

# Agregar a fstab para montaje persistente
echo "$NFS_SERVER:/srv/nfs/appfiles $STORAGE_BASE_PATH nfs4 defaults,_netdev,hard,intr 0 0" >> /etc/fstab

echo "NFS montado y configurado en $STORAGE_BASE_PATH"

# Clone repository and deploy services
yum install -y git || true
cd /opt/anbapp

# Clone repository
echo "Clonando repositorio..."
git clone -b entrega-2 https://github.com/Carlos-Rodriguez98/ANB-WebApp.git repo || {
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

/usr/local/bin/docker-compose -f docker-compose.web.yml up -d --build

# ============================================
# Poblar base de datos con datos iniciales
# ============================================
echo "Ejecutando script de inicialización de base de datos..."

# Instalar PostgreSQL client
yum install -y postgresql15 || yum install -y postgresql || echo "Warning: Could not install PostgreSQL client"

# Esperar a que RDS esté disponible
echo "Esperando a que RDS esté disponible..."
for i in {1..30}; do
    if PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1" > /dev/null 2>&1; then
        echo "✓ Conexión a RDS establecida"
        break
    else
        echo "Intento $i/30: Esperando RDS..."
        sleep 10
    fi
    if [ $i -eq 30 ]; then
        echo "WARNING: No se pudo conectar a RDS después de 5 minutos. Continuando sin poblar datos..."
    fi
done

# Ejecutar init.sql directamente
INIT_SQL="/opt/anbapp/repo/services/database-service/init.sql"

if [ -f "$INIT_SQL" ]; then
    echo "📄 Ejecutando init.sql..."
    PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f "$INIT_SQL" > /tmp/seed-db.log 2>&1
    
    if [ $? -eq 0 ]; then
        echo "✅ Script ejecutado exitosamente"
        
        # Mostrar resumen
        PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "
            SELECT '👥 Usuarios: ' || COUNT(*) FROM app.users
            UNION ALL
            SELECT '🎬 Videos: ' || COUNT(*) FROM app.videos
            UNION ALL
            SELECT '⭐ Votos: ' || COUNT(*) FROM app.votes;
        " 2>/dev/null || echo "BD inicializada"
    else
        echo "⚠️ Hubo errores al ejecutar el script. Ver /tmp/seed-db.log"
        cat /tmp/seed-db.log
    fi
else
    echo "⚠️ No se encontró $INIT_SQL"
fi

# /usr/local/bin/docker-compose -f docker-compose.web.yml up --build
# /usr/local/bin/docker-compose -f docker-compose.web.yml down

# Create manual deploy script for future use
cat > /opt/anbapp/deploy.sh <<'DEPLOY_SCRIPT'
#!/bin/bash
set -e
cd /opt/anbapp/repo/infra
cp /opt/anbapp/.env /opt/anbapp/repo/infra/.env
set -a
source /opt/anbapp/.env
set +a
/usr/local/bin/docker-compose -f docker-compose.web.yml up -d --build
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
   /usr/local/bin/docker-compose -f docker-compose.web.yml logs -f

Para reiniciar servicios:
   sudo /opt/anbapp/deploy.sh

Para detener servicios:
   cd /opt/anbapp/repo/infra
   /usr/local/bin/docker-compose -f docker-compose.web.yml down

Servicios disponibles:
   - Frontend: http://localhost:8084
   - Auth: http://localhost:8080
   - Video: http://localhost:8081
   - Voting: http://localhost:8082
   - Ranking: http://localhost:8083
README

echo "Despliegue completado. Ver /opt/anbapp/README.txt para más información."
