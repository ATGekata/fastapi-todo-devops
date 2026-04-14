# FastAPI Todo DevOps

Учебный DevOps-портфолио-проект на базе FastAPI, в котором основной акцент сделан не на сложной бизнес-логике, а на полном жизненном цикле сервиса:

- тесты;
- контейнеризация;
- сборка образа;
- публикация в registry;
- deploy через Docker Compose;
- reverse proxy через Nginx;
- post-deploy проверки;
- smoke test;
- rollback;
- backup/restore;
- recovery-процедуры;
- bootstrap нового сервера.

---

## Что это за проект

Приложение представляет собой небольшой Todo API с хранением данных в PostgreSQL через SQLAlchemy и миграциями Alembic.

Проект используется как учебный стенд для отработки практических DevOps-задач:

- CI/CD;
- runtime через Docker Compose;
- migration-first deploy;
- post-deploy verification;
- базового rollback;
- backup и controlled restore;
- recovery runbook;
- reproducible bootstrap нового сервера.

---

## Что уже умеет проект

На текущем этапе проект уже включает:

- FastAPI Todo API на PostgreSQL;
- Alembic migrations;
- Docker image build и runtime через Docker Compose;
- reverse proxy через Nginx;
- GitLab CI/CD pipeline;
- post-deploy health check;
- отдельный smoke test;
- rollback на предыдущий image;
- backup/restore сценарии PostgreSQL;
- recovery playbook;
- bootstrap-скрипт для Debian-based сервера;
- Prometheus-compatible `/metrics` endpoint.

---

## Стек

- FastAPI
- PostgreSQL
- SQLAlchemy 2.x
- Alembic
- Pytest
- Docker / Docker Compose
- GitLab CI/CD
- Nginx
- Prometheus metrics
- Bash

---

## Архитектура

### Поставка приложения

`Developer -> GitLab CI/CD -> Docker build -> GitLab Container Registry -> deploy.sh -> Docker Compose -> Nginx -> FastAPI -> PostgreSQL`

### Обработка запроса в рантайме

`Client -> Nginx -> FastAPI -> PostgreSQL`

### Migration-first deploy

Правильный порядок запуска сервиса в проекте такой:

1. поднять `db`;
2. дождаться готовности PostgreSQL;
3. выполнить `alembic upgrade head`;
4. поднять `app` и `nginx`;
5. проверить `/health`;
6. прогнать smoke test.

---

## Состав репозитория

- `app/` — FastAPI-приложение, модели и подключение к БД.
- `alembic/` — миграции базы данных.
- `tests/` — API- и integration-oriented тесты.
- `scripts/` — служебные скрипты bootstrap, smoke test, backup, restore и recovery.
- `nginx/` — конфигурация reverse proxy.
- `docs/RECOVERY_PLAYBOOK.md` — базовый runbook по восстановлению сервиса.
- `deploy.sh` — основной скрипт деплоя и rollback.
- `.gitlab-ci.yml` — CI/CD pipeline.
- `docker-compose.yml` — runtime-стек приложения.
- `Dockerfile` — контейнеризация приложения.

---

## Реализованные endpoints

Сервис отдает:

- `GET /`
- `GET /health`
- `GET /version`
- `GET /db-health`
- `GET /metrics`
- `GET /todos`
- `GET /todos/{todo_id}`
- `POST /todos`
- `PUT /todos/{todo_id}`
- `DELETE /todos/{todo_id}`

### Примеры проверки

```bash
curl http://127.0.0.1:8080/health
curl http://127.0.0.1:8080/version
curl http://127.0.0.1:8080/db-health
curl http://127.0.0.1:8080/todos

curl -X POST http://127.0.0.1:8080/todos \
  -H "Content-Type: application/json" \
  -d '{"title":"example todo","done":false}'

## Можно использовать make

```bash
make help
make full-up
make ps
make health
make db-health
make version
make smoke
make backup
make restore-latest
make recovery-check