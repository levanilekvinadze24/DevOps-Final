#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
IMAGE_TAG="${IMAGE_TAG:-latest}"
BACKUP_DIR="${BACKUP_DIR:-.deploy-backups}"

mkdir -p "$BACKUP_DIR"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_FILE="${BACKUP_DIR}/image-${TIMESTAMP}.txt"

echo "=== Deploy — Observability Lab ==="

if docker compose ps app --format json 2>/dev/null | grep -q '"State":"running"'; then
  CURRENT_IMAGE="$(docker inspect observability-lab-app --format='{{.Config.Image}}' 2>/dev/null || echo 'none')"
  echo "$CURRENT_IMAGE" > "$BACKUP_FILE"
  echo "Saved rollback reference: $CURRENT_IMAGE -> $BACKUP_FILE"
fi

echo "Building and deploying app (tag: ${IMAGE_TAG})..."
docker compose build app
docker compose up -d app

echo "Running post-deployment validation..."
APP_URL="${APP_URL:-http://localhost:5000}" scripts/validate-environment.sh

echo "Deploy completed successfully."
