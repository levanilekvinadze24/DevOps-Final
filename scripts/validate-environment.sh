#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

APP_URL="${APP_URL:-http://localhost:5000}"
MAX_ATTEMPTS="${MAX_ATTEMPTS:-30}"
SLEEP_SECONDS="${SLEEP_SECONDS:-5}"

echo "=== Environment Validation ==="

wait_for_url() {
  local name="$1"
  local url="$2"
  local attempts="${3:-$MAX_ATTEMPTS}"
  local i=1

  while [ "$i" -le "$attempts" ]; do
    if curl -sf "$url" >/dev/null; then
      echo "  [OK] ${name}"
      return 0
    fi
    if [ "$i" -lt "$attempts" ]; then
      echo "  Waiting for ${name}... (${i}/${attempts})"
      sleep "$SLEEP_SECONDS"
    fi
    i=$((i + 1))
  done

  echo "  [FAIL] ${name} (${url})"
  return 1
}

attempt=1
while [ "$attempt" -le "$MAX_ATTEMPTS" ]; do
  if curl -sf "${APP_URL}/health" >/dev/null \
    && curl -sf "${APP_URL}/ready" >/dev/null \
    && curl -sf "${APP_URL}/metrics" | grep -q "app_requests_total"; then
    echo "  [OK] Application health, readiness, and metrics"
    break
  fi
  echo "  Waiting for application... (${attempt}/${MAX_ATTEMPTS})"
  attempt=$((attempt + 1))
  sleep "$SLEEP_SECONDS"
done

if [ "$attempt" -gt "$MAX_ATTEMPTS" ]; then
  echo "ERROR: Application failed validation."
  exit 1
fi

wait_for_url "Prometheus" "http://localhost:9090/-/healthy"
wait_for_url "Alertmanager" "http://localhost:9093/-/healthy"
wait_for_url "Grafana" "http://localhost:3100/api/health" 36
wait_for_url "Loki" "http://localhost:3100/ready"

echo ""
echo "All services validated successfully."
