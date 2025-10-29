#!/usr/bin/env bash
set -euo pipefail

# Parámetros
JMX=${1:-ConfiguracionPruebas.jmx}
JTL=${2:-resultados.jtl}
REPORT_DIR=${3:-report}
SERVICE=jmeter  # nombre del servicio en docker-compose

# Asegurar que el servicio existe y está corriendo
CID=$(docker compose ps -q $SERVICE 2>/dev/null || true)
if [ -z "$CID" ]; then
  echo "El servicio '$SERVICE' no está creado. Ejecuta: docker compose up -d"
  exit 1
fi
RUNNING=$(docker inspect -f '{{.State.Running}}' "$CID")
if [ "$RUNNING" != "true" ]; then
  echo "El contenedor existe pero no está en ejecución. Iniciando..."
  docker start "$CID" >/dev/null
fi

# Comandos con ruta absoluta a jmeter dentro del contenedor
JMETER_BIN="/opt/jmeter/bin/jmeter"
CMD="${JMETER_BIN} -n -t /home/jmeter/${JMX} -l /home/jmeter/${JTL} -j /home/jmeter/jmeter.log && ${JMETER_BIN} -g /home/jmeter/${JTL} -o /home/jmeter/${REPORT_DIR}"

echo "Ejecutando prueba: ${JMX} -> ${JTL} (report: ${REPORT_DIR})"
docker compose exec -T $SERVICE bash -lc "$CMD"

echo "Reporte generado en: ./${REPORT_DIR}/index.html"