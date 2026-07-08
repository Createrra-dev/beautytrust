# Секреты и конфигурация продакшена

Секреты **не хранятся в Git**. Источник правды на сервере:

- `deploy/.env` — пароли БД, JWT, T-Bank, Telegram, Zvonok, Sentry, Redis
- Файлы в `backend/data/` — загрузки (аватары, вложения)

## Рекомендации

1. Копируйте `deploy/.env.example` → `deploy/.env` и задайте уникальные значения.
2. `AUTH_JWT_SECRET`, `POSTGRES_PASSWORD`, `ADMIN_TOKEN`, `METRICS_TOKEN` — длинные случайные строки.
3. `SENTRY_DSN` — опционально, для мониторинга ошибок.
4. `REDIS_URL=redis://127.0.0.1:6379/0` — кэш и rate limit (API в `network_mode: host`).
5. `FORCE_HTTPS=true` и `APP_ENV=production` на продакшене.
6. Резервные копии: `deploy/scripts/backup-postgres.sh` (cron ежедневно 03:15).
7. SSL: `deploy/scripts/renew-ssl.sh` (cron по понедельникам 04:30).

## GitHub Actions deploy

Добавьте secrets в репозиторий:

- `SSH_HOST` — `5.42.107.134`
- `SSH_USER` — `root`
- `SSH_PASSWORD` — пароль сервера

После push в `main` CI запускает pytest и при успехе деплоит на сервер.
