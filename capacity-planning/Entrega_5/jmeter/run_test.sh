#!/usr/bin/env bash
export MSYS_NO_PATHCONV=1
set -euo pipefail

# Validar que se proporcione el archivo JMX
if [ $# -eq 0 ]; then
    echo "Error: Debes proporcionar el nombre del archivo JMX"
    echo "Uso: $0 <archivo.jmx> [num_runs] [resultados.jtl] [report_dir]"
    echo "Ejemplo: $0 Configuracion.jmx 5"
    exit 1
fi

JMX_FILE=$1
NUM_RUNS=${NUM_RUNS:-5}
JTL=${3:-output/resultados.jtl}
REPORT_DIR=${4:-output/report}
CONTAINER_NAME=jmeter-runner
LOG_FILE=output/jmeter.log
TEMP_DIR=output/temp_runs

# Validar que el archivo JMX exista en el directorio padre
if [ ! -f "../$JMX_FILE" ]; then
    echo "Error: El archivo '../$JMX_FILE' no existe"
    echo "Asegúrate de que el archivo esté en Entrega_4/"
    exit 1
fi

# Validar que el contenedor esté corriendo
if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "Error: El contenedor '$CONTAINER_NAME' no está corriendo"
    echo "Ejecuta primero: docker compose up -d"
    exit 1
fi

# Limpiar archivos anteriores
echo "Limpiando archivos de ejecuciones anteriores..."
docker exec -i "$CONTAINER_NAME" sh -c "
    rm -f /home/jmeter/${LOG_FILE}
    rm -f /home/jmeter/${JTL}
    rm -rf /home/jmeter/${REPORT_DIR}
    rm -rf /home/jmeter/${TEMP_DIR}
    mkdir -p /home/jmeter/${TEMP_DIR}
"
echo "✓ Limpieza completada"
echo ""

echo "Configuración de prueba:"
echo "   Archivo JMX: ${JMX_FILE}"
echo "   Número de ejecuciones: ${NUM_RUNS}"
echo "   Resultados finales: ${JTL}"
echo "   Reporte: ${REPORT_DIR}"
echo ""

VIDEO_SOURCE="../../../collections/mp4_16mb_test.mp4"
VIDEO_DEST="collections/mp4_16mb_test.mp4"

if [ -f "$VIDEO_SOURCE" ]; then
    echo "Copiando archivo de video al contenedor..."
    docker exec -i "$CONTAINER_NAME" mkdir -p /home/jmeter/collections
    docker cp "$VIDEO_SOURCE" "${CONTAINER_NAME}:/home/jmeter/${VIDEO_DEST}"
    echo "✓ Archivo de video copiado: ${VIDEO_DEST}"
    echo ""
else
    echo "Advertencia: No se encontró el archivo de video en ${VIDEO_SOURCE}"
    echo "   Si tu prueba requiere subir videos, esto causará errores."
    echo ""
fi

# Ejecutar JMeter múltiples veces
SUCCESS_COUNT=0
for i in $(seq 1 $NUM_RUNS); do
    echo "Ejecutando prueba ${i}/${NUM_RUNS}..."
    
    TEMP_JTL="${TEMP_DIR}/resultados_run${i}.jtl"
    TEMP_LOG="${TEMP_DIR}/jmeter_run${i}.log"
    TEMP_REPORT="${TEMP_DIR}/report_run${i}"
    
    if docker exec -i "$CONTAINER_NAME" /opt/jmeter/bin/jmeter \
        -n \
        -t "/home/jmeter/${JMX_FILE}" \
        -l "/home/jmeter/${TEMP_JTL}" \
        -j /home/jmeter/${TEMP_LOG} \
        -JUSERS="${USERS:-1}" \
        -JRAMP="${RAMP:-5}" \
        -JPROTOCOL="${PROTOCOL:-http}" \
        -JSERVER_NAME="${SERVER_NAME:-host.docker.internal}" \
        -JALB_PORT="${ALB_PORT:-80}" \
        -JVIDEO_FILE_PATH="${VIDEO_FILE_PATH:-${VIDEO_DEST}}"; then
        
        echo "Ejecución ${i} completada exitosamente"
        
        # Generar reporte individual para esta ejecución
        echo "Generando reporte individual para ejecución ${i}..."
        docker exec -i "$CONTAINER_NAME" /opt/jmeter/bin/jmeter \
            -g /home/jmeter/${TEMP_JTL} \
            -o /home/jmeter/${TEMP_REPORT}
        
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    else
        echo "Ejecución ${i} falló, continuando con las siguientes..."
    fi
    
    # Pausa entre ejecuciones para estabilizar el sistema
    if [ $i -lt $NUM_RUNS ]; then
        echo "Esperando 30 segundos antes de la siguiente ejecución..."
        sleep 30
    fi
    echo ""
done

# Verificar que al menos una ejecución fue exitosa
if [ $SUCCESS_COUNT -eq 0 ]; then
    echo "Error: Todas las ejecuciones fallaron"
    echo "Revisa los logs en: ${TEMP_DIR}/"
    exit 1
fi

echo "📊 Consolidando resultados de ${SUCCESS_COUNT} ejecuciones exitosas..."

# Combinar todos los archivos JTL
docker exec -i "$CONTAINER_NAME" sh -c "
    # Copiar el encabezado del primer archivo
    head -n 1 /home/jmeter/${TEMP_DIR}/resultados_run1.jtl > /home/jmeter/${JTL}
    
    # Agregar datos de todos los archivos (sin encabezado)
    for file in /home/jmeter/${TEMP_DIR}/resultados_run*.jtl; do
        if [ -f \"\$file\" ]; then
            tail -n +2 \"\$file\" >> /home/jmeter/${JTL}
        fi
    done
    
    # Consolidar logs
    cat /home/jmeter/${TEMP_DIR}/jmeter_run*.log > /home/jmeter/${LOG_FILE}
"

echo "✓ Resultados consolidados"
echo ""
echo "📊 Generando reporte HTML consolidado (promedio de todas las ejecuciones)..."

# Generar reporte HTML consolidado con todos los datos
docker exec -i "$CONTAINER_NAME" sh -c \
    "rm -rf /home/jmeter/${REPORT_DIR} && /opt/jmeter/bin/jmeter -g /home/jmeter/${JTL} -o /home/jmeter/${REPORT_DIR}"

# Extraer VIDEO_IDs desde el JTL (host extrae desde el contenedor)
echo "🔎 Extrayendo VIDEO_IDs desde ${JTL} dentro del contenedor..."
FIRST_ID=$(docker exec "$CONTAINER_NAME" sh -c "grep -oE '/api/videos/[0-9]+' /home/jmeter/${JTL} 2>/dev/null | grep -oE '[0-9]+' | head -n1 || true" | tr -d '\r' || true)
LAST_ID=$(docker exec "$CONTAINER_NAME" sh -c "grep -oE '/api/videos/[0-9]+' /home/jmeter/${JTL} 2>/dev/null | grep -oE '[0-9]+' | tail -n1 || true" | tr -d '\r' || true)

# Default a N/A si no se encontraron
if [ -z "${FIRST_ID}" ]; then FIRST_ID="N/A"; fi
if [ -z "${LAST_ID}" ]; then LAST_ID="N/A"; fi

echo "Primer VIDEO_ID detectado: ${FIRST_ID}"
echo "Último VIDEO_ID detectado:  ${LAST_ID}"
echo ""

# Crear página índice HTML personalizada (inyectamos FIRST_ID / LAST_ID)
echo "📄 Creando página de navegación..."
docker exec -i "$CONTAINER_NAME" sh -c "cat > /home/jmeter/${REPORT_DIR}/index_custom.html << EOF
<!DOCTYPE html>
<html lang=\"es\">
<head>
    <meta charset=\"UTF-8\">
    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">
    <title>Reportes JMeter - Ejecuciones Múltiples</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 40px 20px;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
        }
        h1 {
            color: white;
            text-align: center;
            margin-bottom: 40px;
            font-size: 2.5em;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.2);
        }
        .info {
            background: rgba(255,255,255,0.95);
            border-radius: 12px;
            padding: 20px;
            margin-bottom: 30px;
            text-align: center;
        }
        .info h2 { color: #333; margin-bottom: 10px; }
        .info p { color: #555; margin-bottom: 6px; font-size: 1.05em; }
        .reports-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 25px;
            margin-bottom: 40px;
        }
        .report-card {
            background: white;
            border-radius: 15px;
            padding: 30px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.2);
            transition: transform 0.3s ease, box-shadow 0.3s ease;
            text-align: center;
        }
        .report-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 15px 40px rgba(0,0,0,0.3);
        }
        .report-card.consolidated {
            grid-column: 1 / -1;
            background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
            color: white;
        }
        .btn {
            display: inline-block;
            padding: 12px 30px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            text-decoration: none;
            border-radius: 25px;
            font-weight: 600;
            transition: all 0.3s ease;
            box-shadow: 0 4px 15px rgba(102, 126, 234, 0.4);
        }
    </style>
</head>
<body>
    <div class=\"container\">
        <h1>📊 Reportes de Pruebas JMeter</h1>

        <div class=\"info\">
            <h2>📌 Información de Procesamiento de Videos</h2>
            <p><strong>Primer VIDEO_ID procesado:</strong> ${FIRST_ID}</p>
            <p><strong>Último VIDEO_ID procesado:</strong> ${LAST_ID}</p>
            <p>Reporte consolidado de ${SUCCESS_COUNT} ejecuciones.</p>
        </div>

        <div class=\"reports-grid\">
            <div class=\"report-card consolidated\">
                <h2>Reporte Consolidado (Promedio)</h2>
                <p>Este reporte muestra el promedio y estadísticas consolidadas de todas las ejecuciones realizadas.</p>
                <a href=\"index.html\" class=\"btn\">Ver Reporte Consolidado</a>
            </div>
EOF"

# Agregar enlaces a reportes individuales
for i in $(seq 1 $SUCCESS_COUNT); do
    docker exec -i "$CONTAINER_NAME" sh -c "cat >> /home/jmeter/${REPORT_DIR}/index_custom.html << 'EOF'
            <div class=\"report-card\">
                <span class=\"badge\">Ejecución ${i}</span>
                <h2>Reporte Ejecución ${i}</h2>
                <p>Resultados detallados de la ejecución número ${i}.</p>
                <a href=\"/capacity-planning/Entrega_4/jmeter/temp_runs/report_run${i}/index.html\" class=\"btn\">Ver Reporte</a>
            </div>
EOF"
done

docker exec -i "$CONTAINER_NAME" sh -c "cat >> /home/jmeter/${REPORT_DIR}/index_custom.html << 'EOF'
        </div>
    </div>
</body>
</html>
EOF"

echo ""
echo "✅ Prueba completada exitosamente"
echo "📈 Resumen:"
echo "   - Ejecuciones totales: ${NUM_RUNS}"
echo "   - Ejecuciones exitosas: ${SUCCESS_COUNT}"
echo "   - Ejecuciones fallidas: $((NUM_RUNS - SUCCESS_COUNT))"
echo ""
echo "📁 Archivos generados en jmeter/:"
echo "   - ${JTL} (datos consolidados)"
echo "   - ${REPORT_DIR}/index.html (reporte consolidado)"
echo "   - ${REPORT_DIR}/index_custom.html (página de navegación) ⭐"
echo "   - ${TEMP_DIR}/report_run[1-${SUCCESS_COUNT}]/ (reportes individuales)"
echo "   - ${LOG_FILE} (logs consolidados)"
echo ""
echo "💡 Abre la página de navegación para ver todos los reportes:"
echo "   start ${REPORT_DIR}/index_custom.html"