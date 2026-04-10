#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")"

REGISTRY_IMAGE="192.168.1.66:5050/monarch/fastapi-todo-devops"
TARGET_IMAGE="${REGISTRY_IMAGE}:${CI_COMMIT_SHORT_SHA:-latest}"

PREVIOUS_CONTAINER="$(docker compose ps -q app || true)"
PREVIOUS_IMAGE=""

if [ -n "${PREVIOUS_CONTAINER}" ]; then
  PREVIOUS_IMAGE="$(docker inspect --format '{{.Config.Image}}' "${PREVIOUS_CONTAINER}" 2>/dev/null || true)"
fi

echo "Target image: ${TARGET_IMAGE}"
if [ -n "${PREVIOUS_IMAGE}" ]; then
  echo "Previous image: ${PREVIOUS_IMAGE}"
else
  echo "Previous image not found"
fi

docker pull "${TARGET_IMAGE}"

IMAGE_NAME="${TARGET_IMAGE}" docker compose up -d --force-recreate

echo "Waiting for health check through Nginx..."
for i in $(seq 1 20); do
  if curl -fsS http://127.0.0.1:8080/health >/dev/null; then
    echo "Deploy successful"
    exit 0
  fi

  echo "Attempt ${i}/20 failed"
  sleep 3
done

echo "Deploy failed"
echo
echo "=== docker compose ps ==="
docker compose ps || true
echo
echo "=== logs: nginx ==="
docker compose logs nginx || true
echo
echo "=== logs: app ==="
docker compose logs app || true

if [ -n "${PREVIOUS_IMAGE}" ]; then
  echo
  echo "Rolling back to previous image: ${PREVIOUS_IMAGE}"
  docker pull "${PREVIOUS_IMAGE}" || true
  IMAGE_NAME="${PREVIOUS_IMAGE}" docker compose up -d --force-recreate

  for i in $(seq 1 20); do
    if curl -fsS http://127.0.0.1:8080/health >/dev/null; then
      echo "Rollback successful. Service restored."
      exit 1
    fi
    sleep 3
  done

  echo "Rollback failed too"
else
  echo "No previous image available for rollback"
fi

exit 1