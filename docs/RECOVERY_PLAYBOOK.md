---
title: Recovery Playbook — FastAPI Todo DevOps
tags: [devops, recovery, incident-response, postgres, docker-compose, runbook]
---

# Recovery Playbook — FastAPI Todo DevOps

## 1. Цель документа

Этот документ описывает базовые действия по восстановлению сервиса FastAPI Todo DevOps после сбоя.

Цель:
- быстро локализовать проблему;
- понять, какой компонент сломан;
- восстановить сервис по повторяемому сценарию;
- не принимать хаотичных решений в аварии.

---

## 2. Состав сервиса

Основные компоненты:
- `nginx`
- `app`
- `db` (PostgreSQL)

Также используются:
- Docker Compose
- Alembic migrations
- backup/restore scripts
- systemd timer для backup

---

## 3. Базовая диагностика

Сначала всегда выполнить:

```bash
docker compose ps
curl -fsS http://127.0.0.1:8080/health
curl -fsS http://127.0.0.1:8080/db-health
docker compose logs --tail=100 nginx
docker compose logs --tail=100 app
docker compose logs --tail=100 db
