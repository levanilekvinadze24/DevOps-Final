#!/usr/bin/env bash
set -euo pipefail

APP_URL="${APP_URL:-http://localhost:5000}"
INTERVAL="${INTERVAL:-30}"
MAX_FAILURES="${MAX_FAILURES:-3}"

failures=0

echo "Monitoring ${APP_URL}/health every ${INTERVAL}s (max failures: ${MAX_FAILURES})"
echo "Press Ctrl+C to stop."

while true; do
  timestamp="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  if curl -sf "${APP_URL}/health" >/dev/null && curl -sf "${APP_URL}/ready" >/dev/null; then
    failures=0
    echo "[${timestamp}] HEALTHY"
  else
    failures=$((failures + 1))
    echo "[${timestamp}] UNHEALTHY (${failures}/${MAX_FAILURES})"
    if [ "$failures" -ge "$MAX_FAILURES" ]; then
      echo "ALERT: Service failed ${MAX_FAILURES} consecutive checks."
      echo "Suggested action: docker compose logs app --tail=50"
      failures=0
    fi
  fi
  sleep "$INTERVAL"
done
