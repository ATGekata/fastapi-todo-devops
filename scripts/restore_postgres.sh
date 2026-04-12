#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

if [ $# -lt 1 ]; then
  echo "Usage: $0 <backup_file.sql.gz> [restore_db_name]"
  exit 1
fi

BACKUP_FILE="$1"
RESTORE_DB="${2:-todo_restore_check}"

if [ ! -f "$BACKUP_FILE" ]; then
  echo "[restore] Backup file not found: $BACKUP_FILE"
  exit 1
fi

echo "[restore] Using backup file: $BACKUP_FILE"
echo "[restore] Target restore DB: $RESTORE_DB"

echo "[restore] Verifying gzip archive..."
gzip -t "$BACKUP_FILE"

echo "[restore] Recreating restore database..."
docker compose exec -T db sh -lc "
psql -U \"\$POSTGRES_USER\" -d postgres -v ON_ERROR_STOP=1 \
  -c 'DROP DATABASE IF EXISTS ${RESTORE_DB};' \
  -c 'CREATE DATABASE ${RESTORE_DB};'
"

echo "[restore] Restoring dump into ${RESTORE_DB}..."
gunzip -c "$BACKUP_FILE" | docker compose exec -T db sh -lc \
  "psql -U \"\$POSTGRES_USER\" -d ${RESTORE_DB} -v ON_ERROR_STOP=1"

echo "[restore] Checking restored tables..."
docker compose exec -T db sh -lc \
  "psql -U \"\$POSTGRES_USER\" -d ${RESTORE_DB} -c '\dt'"

echo "[restore] Checking restored row count..."
docker compose exec -T db sh -lc \
  "psql -U \"\$POSTGRES_USER\" -d ${RESTORE_DB} -c 'SELECT COUNT(*) FROM todos;'"

echo "[restore] Restore check completed successfully"