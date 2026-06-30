#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
IMAGE_NAME="${IMAGE_NAME:-observability-lab-app:latest}"
BACKUP_DIR="${BACKUP_DIR:-.deploy-backups}"

mkdir -p "$BACKUP_DIR"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_FILE="${BACKUP_DIR}/image-${TIMESTAMP}.txt"
ROLLBACK_TAG="observability-lab-app:rollback-${TIMESTAMP}"

echo "=== Deploy — Observability Lab ==="

if docker compose ps app --format json 2>/dev/null | grep -q '"State":"running"'; then
  if docker image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
    docker tag "$IMAGE_NAME" "$ROLLBACK_TAG"
    echo "$ROLLBACK_TAG" > "$BACKUP_FILE"
    echo "Saved rollback image: ${ROLLBACK_TAG} -> ${BACKUP_FILE}"
  fi
fi

echo "Building and deploying app..."
docker compose build app
docker compose up -d app

echo "Running post-deployment validation..."
APP_URL="${APP_URL:-http://localhost:5000}" scripts/validate-environment.sh

echo "Deploy completed successfully."
