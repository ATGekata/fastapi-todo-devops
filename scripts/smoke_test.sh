#!/usr/bin/env bash
set -euo pipefail

APP_URL="${APP_URL:-http://127.0.0.1:8080}"
EXPECTED_COMMIT_SHA="${EXPECTED_COMMIT_SHA:-}"
MAX_ATTEMPTS="${MAX_ATTEMPTS:-20}"
SLEEP_SECONDS="${SLEEP_SECONDS:-3}"

echo "[smoke] APP_URL=${APP_URL}"
echo "[smoke] EXPECTED_COMMIT_SHA=${EXPECTED_COMMIT_SHA:-<not-set>}"

attempt=1
while [ "$attempt" -le "$MAX_ATTEMPTS" ]; do
  if curl -fsS "${APP_URL}/health" >/dev/null; then
    echo "[smoke] /health OK"
    break
  fi

  echo "[smoke] waiting for /health (${attempt}/${MAX_ATTEMPTS})"
  sleep "$SLEEP_SECONDS"
  attempt=$((attempt + 1))
done

if [ "$attempt" -gt "$MAX_ATTEMPTS" ]; then
  echo "[smoke] ERROR: /health did not become ready in time"
  exit 1
fi

ROOT_RESPONSE="$(curl -fsS "${APP_URL}/")"
echo "[smoke] / => ${ROOT_RESPONSE}"

VERSION_JSON="$(curl -fsS "${APP_URL}/version")"
echo "[smoke] /version => ${VERSION_JSON}"

echo "${VERSION_JSON}" | grep -Eq '"commit_sha"[[:space:]]*:' || {
  echo "[smoke] ERROR: commit_sha field not found in /version response"
  exit 1
}

if [ -n "${EXPECTED_COMMIT_SHA}" ]; then
  echo "${VERSION_JSON}" | grep -Eq "\"commit_sha\"[[:space:]]*:[[:space:]]*\"${EXPECTED_COMMIT_SHA}\"" || {
    echo "[smoke] ERROR: deployed commit does not match expected commit"
    exit 1
  }
fi

TODO_ID=$(
  curl -s -X POST http://localhost/todos \
    -H "Content-Type: application/json" \
    -d '{"title":"smoke todo","done":false}' | jq -r '.id'
)

test -n "$TODO_ID"

curl -fsS http://localhost/todos/"$TODO_ID" > /dev/null

curl -fsS -X PUT http://localhost/todos/"$TODO_ID" \
  -H "Content-Type: application/json" \
  -d '{"title":"smoke todo updated","done":true}' > /dev/null

curl -fsS -X DELETE http://localhost/todos/"$TODO_ID" > /dev/null

echo "[smoke] smoke test passed"