#!/usr/bin/env bash
set -euo pipefail

APP_URL="${APP_URL:-http://127.0.0.1:8080}"

echo "[check] docker compose ps"
docker compose ps || true

echo
echo "[check] /health"
curl -fsS "${APP_URL}/health" || echo "[check] /health failed"

echo
echo "[check] /db-health"
curl -fsS "${APP_URL}/db-health" || echo "[check] /db-health failed"

echo
echo "[check] /version"
curl -fsS "${APP_URL}/version" || echo "[check] /version failed"

echo
echo "[check] recent nginx logs"
docker compose logs --tail=50 nginx || true

echo
echo "[check] recent app logs"
docker compose logs --tail=50 app || true

echo
echo "[check] recent db logs"
docker compose logs --tail=50 db || true
