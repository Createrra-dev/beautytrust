#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR/deploy"

if [[ -f .env ]]; then
	set -a
	# shellcheck disable=SC1091
	source .env
	set +a
fi

if [[ -z "${TELEGRAM_BOT_TOKEN:-}" ]]; then
	echo "TELEGRAM_BOT_TOKEN is not set in deploy/.env"
	exit 1
fi

BASE_URL="${PUBLIC_BASE_URL:-https://apis.beautytrust.ru}"
WEBHOOK_URL="${BASE_URL%/}/api/auth/telegram/webhook"

PAYLOAD=$(TELEGRAM_WEBHOOK_SECRET="${TELEGRAM_WEBHOOK_SECRET:-}" WEBHOOK_URL="$WEBHOOK_URL" python3 - <<'PY'
import json
import os

payload = {
	"url": os.environ["WEBHOOK_URL"],
	"allowed_updates": ["message"],
}
secret = os.environ.get("TELEGRAM_WEBHOOK_SECRET", "").strip()
if secret:
	payload["secret_token"] = secret
print(json.dumps(payload))
PY
)

echo "Setting webhook to ${WEBHOOK_URL}"
curl -sS "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/setWebhook" \
	-H "Content-Type: application/json" \
	-d "$PAYLOAD"
echo
