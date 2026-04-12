#!/usr/bin/env bash
set -euo pipefail

LATEST_BACKUP="$(ls -1t backups/postgres/*.sql.gz | head -n 1)"

if [ -z "${LATEST_BACKUP:-}" ]; then
  echo "[restore-latest] No backup files found"
  exit 1
fi

echo "[restore-latest] Latest backup: ${LATEST_BACKUP}"
./scripts/restore_postgres.sh "$LATEST_BACKUP"
