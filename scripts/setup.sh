#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "=== DevOps Observability Lab — Environment Setup ==="

if ! command -v docker >/dev/null 2>&1; then
  echo "ERROR: Docker is not installed. Install Docker Desktop first."
  exit 1
fi

if ! docker compose version >/dev/null 2>&1; then
  echo "ERROR: Docker Compose v2 is required."
  exit 1
fi

if [ ! -f .env ]; then
  echo "Creating .env from .env.example..."
  cp .env.example .env
fi

echo "Building and starting the full observability stack..."
docker compose down --remove-orphans 2>/dev/null || true
docker compose up -d --build

echo "Waiting for services to become healthy..."
"$ROOT_DIR/scripts/validate-environment.sh"

echo ""
echo "Setup complete. Services:"
echo "  Application:   http://localhost:${APP_PORT:-5000}"
echo "  Prometheus:    http://localhost:9090"
echo "  Grafana:       http://localhost:3000  (admin/admin)"
echo "  Alertmanager:  http://localhost:9093"
echo "  Loki:          http://localhost:3100"
