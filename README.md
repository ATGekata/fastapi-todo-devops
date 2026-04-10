# FastAPI Todo DevOps

Учебный DevOps-портфолио-проект, показывающий полный CI/CD цикл для веб-приложения на примере FastAPI-сервиса.

Проект демонстрирует не столько сложную бизнес-логику приложения, сколько инженерную цепочку поставки:

- автотесты;
- сборка Docker image;
- публикация в GitLab Container Registry;
- автоматический deploy на target host;
- reverse proxy через Nginx;
- post-deploy проверка;
- отдельный smoke test после релиза;
- базовая rollback-логика;
- автоматическое обновление CHANGELOG и Wiki.

---

## О проекте

Это учебный стенд для отработки DevOps-практики на реальном минимальном сервисе.

Приложение — небольшой FastAPI Todo API, который используется как объект доставки для CI/CD-процесса.  
«Создание автоматизированной платформы для непрерывного тестирования и верификации стабильности программного обеспечения на примере веб-приложения с использованием контейнеризации и CI/CD».
Главный фокус проекта — не функциональность ToDo-сервиса, а:

- контейнеризация;
- автоматизация сборки и публикации;
- развертывание через GitLab CI/CD;
- проверка доступности после деплоя;
- верификация версии релиза;
- подготовка к безопасному откату.

---

## Технологии

- FastAPI
- Pytest
- Docker
- Docker Compose
- GitLab CI/CD
- GitLab Runner
- GitLab Container Registry
- Nginx
- Bash

---

## Архитектура

Схема работы проекта:

`Developer -> GitLab CI/CD -> Build image -> Push to Registry -> Deploy on target host -> Docker Compose -> Nginx -> FastAPI app`

В рантайме запрос проходит по цепочке:

`Client -> Nginx -> FastAPI`

---

## Что уже реализовано

### CI/CD pipeline

В проекте реализованы стадии:

- `test`
- `build`
- `deploy`
- `post_deploy`
- `smoke_test`
- `changelog`
- `wiki_update`

### Инфраструктура

- сборка Docker image в GitLab CI;
- публикация образа в GitLab Container Registry;
- deploy через shell runner;
- запуск приложения через Docker Compose;
- reverse proxy через Nginx;
- health-check после деплоя;
- smoke-проверка доступности и версии приложения;
- базовая rollback-логика для неудачного релиза.

### Проверка сервиса

Доступные endpoint'ы:

- `/`
- `/health`
- `/version`
- `/todos`

Примеры проверки на target host:

```bash
curl http://127.0.0.1:8080/
curl http://127.0.0.1:8080/health
curl http://127.0.0.1:8080/version
```
