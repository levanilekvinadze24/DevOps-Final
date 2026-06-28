#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
BACKUP_DIR="${BACKUP_DIR:-.deploy-backups}"

echo "=== Rollback — Observability Lab ==="

LATEST_BACKUP="$(ls -t "${BACKUP_DIR}"/image-*.txt 2>/dev/null | head -1 || true)"
if [ -z "$LATEST_BACKUP" ]; then
  echo "No deployment backup found. Rebuilding previous compose state..."
  docker compose up -d --build app
else
  PREVIOUS_IMAGE="$(cat "$LATEST_BACKUP")"
  echo "Rolling back to: ${PREVIOUS_IMAGE}"
  docker compose stop app
  if [ "$PREVIOUS_IMAGE" != "none" ] && docker image inspect "$PREVIOUS_IMAGE" >/dev/null 2>&1; then
    docker tag "$PREVIOUS_IMAGE" "${COMPOSE_PROJECT_NAME:-observability-lab}-app:latest" 2>/dev/null || true
  fi
  docker compose up -d --build app
fi

echo "Validating rolled-back environment..."
scripts/validate-environment.sh
echo "Rollback completed."
