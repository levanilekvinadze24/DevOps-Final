#!/usr/bin/env bash
# Simulates enough errors to trigger the CRITICAL Prometheus alert (> 5 errors/min)
BASE_URL="${BASE_URL:-http://localhost:5000}"
ERROR_COUNT="${ERROR_COUNT:-10}"

echo "Generating ${ERROR_COUNT} errors to trigger CRITICAL alert..."
for i in $(seq 1 "$ERROR_COUNT"); do
  curl -s "${BASE_URL}/api/error?type=alert_simulation" > /dev/null
  echo "  Error ${i}/${ERROR_COUNT} sent"
done

echo ""
echo "Done. Wait 1-2 minutes, then verify:"
echo "  Prometheus alerts: http://localhost:9090/alerts"
echo "  Grafana alerting:  http://localhost:3000/alerting/list (admin/admin)"
