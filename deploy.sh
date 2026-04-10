#!/bin/bash
set -e

cd "$(dirname "$0")"

docker pull 192.168.1.66:5050/monarch/fastapi-todo-devops:latest
docker compose down
docker compose up -d

echo "Ожидаем доступность сервиса через Nginx..."
for i in $(seq 1 20); do
  if curl -fsS http://127.0.0.1:8080/health >/dev/null; then
    echo "Health check через Nginx прошёл успешно"
    exit 0
  fi

  echo "Попытка $i/20: сервис ещё недоступен"
  sleep 3
done

echo "Сервис не поднялся через Nginx вовремя"
echo
echo "=== docker compose ps ==="
docker compose ps || true
echo
echo "=== logs: nginx ==="
docker compose logs nginx || true
echo
echo "=== logs: app ==="
docker compose logs app || true

exit 1