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
REDIS_ADDR="${REDIS_ADDR}"
REDIS_PORT="${REDIS_PORT}"

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
REDIS_ADDR=$REDIS_ADDR
REDIS_PORT=$REDIS_PORT
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

# Clone repository and deploy services
yum install -y git || true
cd /opt/anbapp

# Clone repository
echo "Clonando repositorio..."
git clone -b dev https://github.com/Carlos-Rodriguez98/ANB-WebApp.git repo || {
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
