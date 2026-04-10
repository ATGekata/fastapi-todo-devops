#!/bin/bash
set -e

cd "$(dirname "$0")"

docker pull 192.168.1.66:5050/monarch/fastapi-todo-devops:latest
docker compose down
docker compose up -d

sleep 8
curl -f http://127.0.0.1:8080/health