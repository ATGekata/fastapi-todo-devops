#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

REGISTRY_IMAGE="192.168.1.66:5050/monarch/fastapi-todo-devops"
TARGET_IMAGE="${REGISTRY_IMAGE}:${CI_COMMIT_SHORT_SHA:-latest}"

compose_with_image() {
  local image="$1"
  shift

  IMAGE_NAME="${image}" \
  APP_COMMIT_SHA="${CI_COMMIT_SHORT_SHA:-local}" \
  APP_RELEASE="${image}" \
  docker compose "$@"
}

PREVIOUS_CONTAINER="$(docker compose ps -q app || true)"
PREVIOUS_IMAGE=""

if [ -n "${PREVIOUS_CONTAINER}" ]; then
  PREVIOUS_IMAGE="$(docker inspect --format '{{.Config.Image}}' "${PREVIOUS_CONTAINER}" 2>/dev/null || true)"
fi

echo "[deploy] Target image: ${TARGET_IMAGE}"
if [ -n "${PREVIOUS_IMAGE}" ]; then
  echo "[deploy] Previous image: ${PREVIOUS_IMAGE}"
else
  echo "[deploy] Previous image not found"
fi

echo "[deploy] Pulling target image..."
docker pull "${TARGET_IMAGE}"

echo "[deploy] Starting db only..."
compose_with_image "${TARGET_IMAGE}" up -d db

echo "[deploy] Waiting for PostgreSQL..."
until docker compose exec -T db pg_isready -U "${POSTGRES_USER:-todo_user}" -d "${POSTGRES_DB:-todo_db}" >/dev/null 2>&1; do
  echo "[deploy] PostgreSQL is not ready yet..."
  sleep 2
done

echo "[deploy] Running Alembic migrations..."
compose_with_image "${TARGET_IMAGE}" run --rm -T app \
  sh -lc 'cd /app && python -m alembic -c /app/alembic.ini upgrade head'

echo "[deploy] Starting app and nginx..."
compose_with_image "${TARGET_IMAGE}" up -d --force-recreate app nginx

echo "[deploy] Waiting for health check through Nginx..."
for i in $(seq 1 20); do
  if curl -fsS http://127.0.0.1:8080/health >/dev/null; then
    echo "[deploy] Deploy successful"
    exit 0
  fi

  echo "[deploy] Health check failed: attempt ${i}/20"
  sleep 3
done

echo "[deploy] Deploy failed"
echo
echo "=== docker compose ps ==="
docker compose ps || true
echo
echo "=== logs: db ==="
docker compose logs db || true
echo
echo "=== logs: app ==="
docker compose logs app || true
echo
echo "=== logs: nginx ==="
docker compose logs nginx || true

if [ -n "${PREVIOUS_IMAGE}" ]; then
  echo
  echo "[deploy] Rolling back to previous image: ${PREVIOUS_IMAGE}"
  docker pull "${PREVIOUS_IMAGE}" || true

  compose_with_image "${PREVIOUS_IMAGE}" up -d --force-recreate app nginx

  for i in $(seq 1 20); do
    if curl -fsS http://127.0.0.1:8080/health >/dev/null; then
      echo "[deploy] Rollback successful. Service restored."
      exit 1
    fi

    echo "[deploy] Rollback health check failed: attempt ${i}/20"
    sleep 3
  done

  echo "[deploy] Rollback failed too"
else
  echo "[deploy] No previous image available for rollback"
fi

exit 1