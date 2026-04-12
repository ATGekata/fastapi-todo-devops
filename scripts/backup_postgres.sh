#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

BACKUP_ROOT="backups/postgres"
RETENTION_DAYS="${RETENTION_DAYS:-7}"

mkdir -p "$BACKUP_ROOT"

TS="$(date +%F_%H-%M-%S)"
BACKUP_FILE="${BACKUP_ROOT}/todo_db_${TS}.sql.gz"

echo "[backup] Creating PostgreSQL backup: ${BACKUP_FILE}"

docker compose exec -T db sh -lc 'pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB"' \
  | gzip > "$BACKUP_FILE"

echo "[backup] Verifying gzip archive..."
gzip -t "$BACKUP_FILE"

echo "[backup] Removing backups older than ${RETENTION_DAYS} days..."
find "$BACKUP_ROOT" -type f -name 'todo_db_*.sql.gz' -mtime +"$RETENTION_DAYS" -print -delete

echo "[backup] Done"
ls -lh "$BACKUP_FILE"