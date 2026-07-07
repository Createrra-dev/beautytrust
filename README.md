# T-Bank Payment Test

Тестовое Flutter-приложение для проверки приёма оплат через **T-Bank Интернет-Эквайринг** с **универсальным подключением**.

Схема работы:

1. Flutter-приложение вызывает **FastAPI-бэкенд**
2. Бэкенд создаёт платёж через `POST /v2/Init` (Terminal Key + Password)
3. Приложение открывает `PaymentURL` в WebView
4. Пользователь оплачивает картой на платёжной форме T-Bank (10 ₽)

## Структура

```
backend/          # FastAPI — Init, GetState, return URLs
lib/              # Flutter — кнопка «Оплатить» + WebView
```

## 1. Запуск бэкенда

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
```

Заполните `backend/.env`:

```env
TBANK_TERMINAL_KEY=1699985942479DEMO
TBANK_PASSWORD=ваш_пароль_терминала
TBANK_API_URL=https://securepay.tinkoff.ru/v2
PUBLIC_BASE_URL=http://127.0.0.1:8000
```

Для терминала **DEMO** используйте боевой URL `https://securepay.tinkoff.ru/v2`.

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Документация API: http://127.0.0.1:8000/docs  
Админка: http://127.0.0.1:8000/admin

## 2. Запуск Flutter-приложения

```bash
flutter pub get
```

Укажите URL бэкенда, **доступный с устройства**:

| Среда | API_BASE_URL |
|---|---|
| iOS Simulator | `http://127.0.0.1:8000` |
| Android Emulator | `http://10.0.2.2:8000` |
| Физическое устройство | `http://192.168.x.x:8000` (IP вашего компьютера в LAN) |

```bash
# iOS Simulator
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000

# Android Emulator
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

> `return_base_url` передаётся в Init автоматически — T-Bank после оплаты вернёт пользователя на `{API_BASE_URL}/payments/return/success` или `/fail`, и WebView закроется.

## Тестовые карты

[Документация T-Bank](https://developer.tbank.ru/eacq/intro/errors/test):

- `4111111111111111`
- Срок: любой будущий (например, `12/30`)
- CVV: `123`

## API бэкенда

| Метод | Путь | Описание |
|---|---|---|
| GET | `/api/payments/health` | Проверка конфигурации |
| POST | `/api/payments/init` | Создать платёж, вернуть `payment_url` |
| GET | `/api/payments/{id}/status` | Статус платежа (GetState) |
| GET | `/payments/return/success` | Redirect после успеха |
| GET | `/payments/return/fail` | Redirect после ошибки |
| GET | `/admin` | Админка: список попыток оплат |
| POST | `/admin/api/payments/{id}/refresh` | Перезапросить статус из T-Bank |
| POST | `/admin/api/payments/refresh-all` | Обновить все незавершённые |

## Безопасность

- **Пароль терминала** хранится только на бэкенде в `.env`
- В мобильное приложение секреты не попадают
- Файл `backend/.env` добавлен в `.gitignore`
