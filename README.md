# FastAPI Todo DevOps

Учебный DevOps-проект на базе FastAPI, в котором основной акцент сделан не на бизнес-логике, а на полном жизненном цикле поставки приложения: тесты, сборка контейнера, публикация образа, деплой, проверка релиза, базовый rollback и процедуры восстановления.

## Что это за проект

Приложение представляет собой небольшой Todo API с хранением данных в PostgreSQL через SQLAlchemy и миграциями Alembic.

Проект используется как учебный стенд для отработки:

- контейнеризации приложения;
- CI/CD в GitLab;
- деплоя через Docker Compose;
- reverse proxy через Nginx;
- post-deploy и smoke-проверок;
- базового rollback;
- backup/restore сценариев для PostgreSQL.

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

## Архитектура

Поставка приложения:

`Developer -> GitLab CI/CD -> Docker build -> GitLab Container Registry -> deploy.sh -> Docker Compose -> Nginx -> FastAPI -> PostgreSQL`

Обработка запроса в рантайме:

`Client -> Nginx -> FastAPI -> PostgreSQL`

## Состав репозитория

- `app/` — FastAPI-приложение, модели и подключение к БД.
- `alembic/` — миграции базы данных.
- `tests/` — API- и smoke-oriented unit/integration tests.
- `scripts/` — служебные скрипты bootstrap, smoke test, backup и restore.
- `nginx/` — конфигурация reverse proxy.
- `docs/RECOVERY_PLAYBOOK.md` — базовый runbook по восстановлению сервиса.
- `deploy.sh` — основной скрипт деплоя и rollback.
- `.gitlab-ci.yml` — CI/CD pipeline.

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

Примеры:

```bash
curl http://127.0.0.1:8080/health
curl http://127.0.0.1:8080/version
curl http://127.0.0.1:8080/db-health
curl http://127.0.0.1:8080/todos

curl -X POST http://127.0.0.1:8080/todos \
  -H "Content-Type: application/json" \
  -d '{"title":"example todo","done":false}'
```

## Локальный запуск

### 1. Подготовить окружение

Нужен файл `.env` с переменными:

```env
POSTGRES_DB=todo_db
POSTGRES_USER=todo_user
POSTGRES_PASSWORD=change_me_dev_only
POSTGRES_PORT=5432
DATABASE_URL=postgresql+psycopg://todo_user:change_me_dev_only@db:5432/todo_db
```

### 2. Запустить контейнеры

```bash
docker compose up -d
```

Приложение будет доступно через Nginx на `http://127.0.0.1:8080`.

### 3. Применить миграции

Для первого старта или после изменений схемы:

```bash
docker compose run --rm -T app sh -lc 'cd /app && python -m alembic -c /app/alembic.ini upgrade head'
```

## Запуск тестов

Для локального запуска тестов нужен доступный PostgreSQL и корректный `DATABASE_URL`.

Пример:

```bash
source venv/bin/activate
export DATABASE_URL="postgresql+psycopg://todo_user:change_me_dev_only@127.0.0.1:5432/todo_db"
export PYTHONPATH="$PWD"
alembic upgrade head
pytest -v
```

## CI/CD pipeline

В `.gitlab-ci.yml` настроены стадии:

- `test`
- `build`
- `deploy`
- `post_deploy`
- `smoke_test`
- `changelog`
- `wiki_update`

Что делает pipeline:

- поднимает PostgreSQL service для тестов;
- устанавливает зависимости и прогоняет `pytest`;
- применяет миграции Alembic в CI;
- собирает Docker image;
- публикует образ в GitLab Container Registry;
- деплоит образ на target host;
- проверяет `/health` после релиза;
- запускает отдельный smoke test со сверкой `commit_sha`;
- обновляет `CHANGELOG.md`;
- обновляет Wiki в GitLab.

## Как устроен деплой

Сценарий в `deploy.sh` делает следующее:

1. Определяет target image по `CI_COMMIT_SHORT_SHA`.
2. Запоминает предыдущий image запущенного контейнера `app`.
3. Выполняет `docker pull`.
4. Поднимает `db` и ждет готовности PostgreSQL.
5. Запускает Alembic migrations внутри контейнера приложения.
6. Перезапускает `app` и `nginx`.
7. Проверяет `http://127.0.0.1:8080/health`.
8. При ошибке пытается вернуть предыдущий image.

Во время запуска контейнер приложения получает:

- `APP_COMMIT_SHA`
- `APP_RELEASE`

Именно они используются в endpoint `GET /version`.

## Smoke test

Скрипт `scripts/smoke_test.sh` проверяет:

- доступность `/health`;
- ответ `/db-health`;
- ответ `/`;
- наличие `commit_sha` в `/version`;
- совпадение `commit_sha` с ожидаемым релизом;
- полный CRUD-цикл для `/todos`.

## Bootstrap сервера

Для подготовки Debian-based хоста есть `scripts/bootstrap_server.sh`.

Скрипт:

- обновляет apt index;
- устанавливает базовые пакеты;
- ставит Docker и Compose plugin, если их нет;
- добавляет пользователя в группу `docker`;
- создает директорию проекта.

Пример:

```bash
chmod +x scripts/bootstrap_server.sh
PROJECT_DIR=/opt/fastapi-todo-devops TARGET_USER=$USER ./scripts/bootstrap_server.sh
```

После добавления пользователя в группу `docker` может понадобиться повторный вход в сессию.

## Backup и восстановление

В репозитории есть скрипты:

- `scripts/backup_postgres.sh`
- `scripts/restore_postgres.sh`
- `scripts/restore_latest_backup.sh`
- `scripts/recovery_check.sh`

Также есть `docs/RECOVERY_PLAYBOOK.md` с базовым сценарием диагностики и восстановления после сбоя.

Папка `backups/` используется для хранения резервных копий, включая дампы PostgreSQL.

## Полезные замечания

- Для тестов `DATABASE_URL` обязателен: без него приложение не сможет открыть сессию SQLAlchemy.
- В локальном `docker-compose.yml` приложение слушает внутренний порт `8000`, наружу публикуется `8080` через Nginx.
- Endpoint `/metrics` исключен из общей instrumentation-обвязки и экспортируется отдельно для Prometheus scraping.

## Лицензия

См. файл `LICENSE`.
