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

DB_HEALTH_JSON="$(curl -fsS "${APP_URL}/db-health")"
echo "[smoke] /db-health => ${DB_HEALTH_JSON}"

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

CREATE_JSON="$(
  curl -fsS -X POST "${APP_URL}/todos" \
    -H "Content-Type: application/json" \
    -d '{"title":"smoke todo","done":false}'
)"
echo "[smoke] POST /todos => ${CREATE_JSON}"

TODO_ID="$(
  printf '%s' "${CREATE_JSON}" | python3 -c 'import sys, json; print(json.load(sys.stdin)["id"])'
)"

test -n "${TODO_ID}"

GET_JSON="$(curl -fsS "${APP_URL}/todos/${TODO_ID}")"
echo "[smoke] GET /todos/${TODO_ID} => ${GET_JSON}"

UPDATE_JSON="$(
  curl -fsS -X PUT "${APP_URL}/todos/${TODO_ID}" \
    -H "Content-Type: application/json" \
    -d '{"title":"smoke todo updated","done":true}'
)"
echo "[smoke] PUT /todos/${TODO_ID} => ${UPDATE_JSON}"

DELETE_JSON="$(curl -fsS -X DELETE "${APP_URL}/todos/${TODO_ID}")"
echo "[smoke] DELETE /todos/${TODO_ID} => ${DELETE_JSON}"

DELETE_STATUS="$(
  curl -s -o /dev/null -w "%{http_code}" "${APP_URL}/todos/${TODO_ID}"
)"

if [ "${DELETE_STATUS}" != "404" ]; then
  echo "[smoke] ERROR: expected 404 after delete, got ${DELETE_STATUS}"
  exit 1
fi

echo "[smoke] smoke test passed"