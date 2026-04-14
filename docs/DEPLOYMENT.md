---
title: FastAPI Todo API with GitLab CI/CD, Docker Compose deployment, Nginx reverse proxy, smoke tests, rollback and PostgreSQL backup/restore.
tags: [deployment, devops, docker-compose, alembic, nginx, postgres, smoke, rollback]
---

# FastAPI Todo API with GitLab CI/CD, Docker Compose deployment, Nginx reverse proxy, smoke tests, rollback and PostgreSQL backup/restore.

## 1. Назначение документа

Этот документ описывает, как разворачивается сервис FastAPI Todo DevOps и в каком порядке нужно выполнять шаги, чтобы deploy был предсказуемым и безопасным.

Цель этого deployment flow:

- не запускать приложение на неподготовленной БД;
- не смешивать bootstrap, migration и runtime;
- иметь понятный post-deploy check;
- иметь базовый rollback path;
- сделать запуск сервиса повторяемым.

---

## 2. Состав runtime-стека

В проекте участвуют 3 основных runtime-компонента:

- `db` — PostgreSQL
- `app` — FastAPI-приложение
- `nginx` — reverse proxy

Также в release flow участвуют:

- Docker image из registry
- `docker-compose.yml`
- `deploy.sh`
- Alembic migrations
- `scripts/smoke_test.sh`

---

## 3. Базовая идея deploy flow

В этом проекте используется **migration-first deploy**.

Это означает, что приложение не должно стартовать раньше, чем:

1. поднята БД;
2. PostgreSQL реально готов принимать подключения;
3. схема БД приведена к актуальному состоянию через Alembic.

### Правильный порядок такой

1. определить target image;
2. подтянуть image;
3. поднять только `db`;
4. дождаться readiness PostgreSQL;
5. выполнить `alembic upgrade head`;
6. поднять `app` и `nginx`;
7. проверить `/health`;
8. прогнать smoke test;
9. при необходимости выполнить rollback.

---

## 4. Какие файлы участвуют в deploy

### `docker-compose.yml`
Описывает runtime-стек:
- `db`
- `app`
- `nginx`

### `deploy.sh`
Основной operational-скрипт деплоя.  
Он отвечает за:
- pull нужного image;
- запуск БД;
- ожидание PostgreSQL;
- migration-step;
- запуск `app` и `nginx`;
- health-check;
- rollback на предыдущий image.

### `alembic/` и `alembic.ini`
Отвечают за lifecycle схемы БД.

### `.env`
Передаёт runtime-переменные:
- `POSTGRES_DB`
- `POSTGRES_USER`
- `POSTGRES_PASSWORD`
- `POSTGRES_PORT`
- `DATABASE_URL`

### `scripts/smoke_test.sh`
Проверяет, что сервис после deploy реально работает.

---

## 5. Требуемые переменные окружения

Минимально нужны:

```env
POSTGRES_DB=todo_db
POSTGRES_USER=todo_user
POSTGRES_PASSWORD=change_me_dev_only
POSTGRES_PORT=5432
DATABASE_URL=postgresql+psycopg://todo_user:change_me_dev_only@db:5432/todo_db
APP_COMMIT_SHA=local
APP_RELEASE=dev