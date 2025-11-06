#!/usr/bin/env bash
export MSYS_NO_PATHCONV=1
set -euo pipefail

# Validar que se proporcione el archivo JMX
if [ $# -eq 0 ]; then
    echo "❌ Error: Debes proporcionar el nombre del archivo JMX"
    echo "Uso: $0 <archivo.jmx> [resultados.jtl] [report_dir]"
    echo "Ejemplo: $0 ConfiguracionEscenario1.jmx"
    exit 1
fi

JMX_FILE=$1
JTL=${2:-output/resultados.jtl}
REPORT_DIR=${3:-output/report}
CONTAINER_NAME=jmeter-runner

# Validar que el archivo JMX exista en el directorio padre
if [ ! -f "../$JMX_FILE" ]; then
    echo "❌ Error: El archivo '../$JMX_FILE' no existe"
    echo "Asegúrate de que el archivo esté en Entrega_2/"
    exit 1
fi

# Validar que el contenedor esté corriendo
if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "❌ Error: El contenedor '$CONTAINER_NAME' no está corriendo"
    echo "Ejecuta primero: docker compose up -d"
    exit 1
fi

echo "📋 Configuración de prueba:"
echo "   Archivo JMX: ${JMX_FILE}"
echo "   Resultados: ${JTL}"
echo "   Reporte: ${REPORT_DIR}"
echo ""
echo "🚀 Ejecutando JMeter..."

# Ejecutar JMeter
if docker exec -i "$CONTAINER_NAME" /opt/jmeter/bin/jmeter \
    -n \
    -t "/home/jmeter/${JMX_FILE}" \
    -l "/home/jmeter/${JTL}" \
    -j /home/jmeter/output/jmeter.log \
    -JUSERS="${USERS:-1}" \
    -JRAMP="${RAMP:-5}" \
    -JPROTOCOL="${PROTOCOL:-http}" \
    -JSERVER_NAME="${SERVER_NAME:-host.docker.internal}" \
    -JAUTH_SERVICE_PORT="${AUTH_SERVICE_PORT:-8080}" \
    -JPUBLIC_VIDEO_SERVICE_PORT="${PUBLIC_VIDEO_SERVICE_PORT:-8082}" \
    -JRANKING_SERVICE_PORT="${RANKING_SERVICE_PORT:-8083}"; then

    echo ""
    echo "📊 Generando reporte HTML..."
    
    # Generar reporte HTML
    docker exec -i "$CONTAINER_NAME" sh -c \
        "rm -rf /home/jmeter/${REPORT_DIR} && /opt/jmeter/bin/jmeter -g /home/jmeter/${JTL} -o /home/jmeter/${REPORT_DIR}"
    
    echo ""
    echo "✅ Prueba completada exitosamente"
    echo "📁 Archivos generados en jmeter/:"
    echo "   - resultados.jtl"
    echo "   - report/index.html"
    echo "   - jmeter.log"
    echo ""
    echo "Para ver el reporte: start report/index.html"
else
    echo ""
    echo "❌ Error: La ejecución de JMeter falló"
    echo "Revisa los logs en: jmeter.log"
    exit 1
fi