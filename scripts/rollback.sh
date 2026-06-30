#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
IMAGE_NAME="${IMAGE_NAME:-observability-lab-app:latest}"
BACKUP_DIR="${BACKUP_DIR:-.deploy-backups}"

echo "=== Rollback — Observability Lab ==="

LATEST_BACKUP="$(ls -t "${BACKUP_DIR}"/image-*.txt 2>/dev/null | head -1 || true)"
if [ -z "$LATEST_BACKUP" ]; then
  echo "No deployment backup found. Run deploy.sh first to create a rollback point."
  exit 1
fi

PREVIOUS_IMAGE="$(tr -d '[:space:]' < "$LATEST_BACKUP")"
echo "Rolling back to: ${PREVIOUS_IMAGE} (from ${LATEST_BACKUP})"

if ! docker image inspect "$PREVIOUS_IMAGE" >/dev/null 2>&1; then
  echo "Rollback image '${PREVIOUS_IMAGE}' not found locally. Cannot roll back."
  exit 1
fi

docker compose stop app
docker tag "$PREVIOUS_IMAGE" "$IMAGE_NAME"
docker compose up -d --no-build app

scripts/validate-environment.sh
echo "Rollback completed."
