.PHONY: help up down restart ps logs logs-app logs-db logs-nginx \
        db-up db-ready migrate app-up full-up \
        health db-health version smoke \
        test backup restore-latest recovery-check bootstrap

APP_URL ?= http://127.0.0.1:8080

help:
	@echo "Available targets:"
	@echo "  make up              - Start full runtime stack"
	@echo "  make down            - Stop runtime stack"
	@echo "  make restart         - Restart runtime stack"
	@echo "  make ps              - Show compose services status"
	@echo "  make logs            - Show recent logs for all services"
	@echo "  make logs-app        - Show recent app logs"
	@echo "  make logs-db         - Show recent db logs"
	@echo "  make logs-nginx      - Show recent nginx logs"
	@echo "  make db-up           - Start only PostgreSQL"
	@echo "  make db-ready        - Wait until PostgreSQL is ready"
	@echo "  make migrate         - Apply Alembic migrations"
	@echo "  make app-up          - Start app and nginx"
	@echo "  make full-up         - Start db, wait, migrate, start app/nginx"
	@echo "  make health          - Check /health"
	@echo "  make db-health       - Check /db-health"
	@echo "  make version         - Check /version"
	@echo "  make smoke           - Run smoke test"
	@echo "  make test            - Run pytest locally"
	@echo "  make backup          - Create PostgreSQL backup"
	@echo "  make restore-latest  - Restore latest backup into restore DB"
	@echo "  make recovery-check  - Run recovery diagnostics"
	@echo "  make bootstrap       - Run host bootstrap script"

up:
	docker compose up -d

down:
	docker compose down

restart:
	docker compose down
	docker compose up -d

ps:
	docker compose ps

logs:
	docker compose logs --tail=100

logs-app:
	docker compose logs --tail=100 app

logs-db:
	docker compose logs --tail=100 db

logs-nginx:
	docker compose logs --tail=100 nginx

db-up:
	docker compose up -d db

db-ready:
	until docker compose exec -T db pg_isready -U "$${POSTGRES_USER}" -d "$${POSTGRES_DB}" >/dev/null 2>&1; do \
		echo "Waiting for PostgreSQL..."; \
		sleep 2; \
	done

migrate:
	docker compose run --rm -T app sh -lc 'cd /app && python -m alembic -c /app/alembic.ini upgrade head'

app-up:
	docker compose up -d app nginx

full-up: db-up db-ready migrate app-up

health:
	curl -fsS "$(APP_URL)/health"

db-health:
	curl -fsS "$(APP_URL)/db-health"

version:
	curl -fsS "$(APP_URL)/version"

smoke:
	APP_URL="$(APP_URL)" ./scripts/smoke_test.sh

test:
	pytest -v

backup:
	./scripts/backup_postgres.sh

restore-latest:
	./scripts/restore_latest_backup.sh

recovery-check:
	./scripts/recovery_check.sh

bootstrap:
	./scripts/bootstrap_server.sh