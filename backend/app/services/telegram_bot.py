import logging

import httpx

from app.config import settings

logger = logging.getLogger(__name__)


class TelegramBotError(Exception):
	pass


def _api_url(method: str) -> str:
	if not settings.telegram_bot_token:
		raise TelegramBotError("Telegram bot token is not configured")
	return f"https://api.telegram.org/bot{settings.telegram_bot_token}/{method}"


async def send_message(chat_id: int, text: str) -> None:
	async with httpx.AsyncClient(timeout=30.0) as client:
		response = await client.post(
			_api_url("sendMessage"),
			json={
				"chat_id": chat_id,
				"text": text,
				"parse_mode": "HTML",
			},
		)
		payload = response.json()
		if not payload.get("ok"):
			logger.error("Telegram sendMessage failed: %s", payload)
			raise TelegramBotError(payload.get("description", "Failed to send Telegram message"))


async def setup_webhook() -> None:
	if not settings.telegram_bot_token:
		logger.warning("Telegram bot token missing, webhook not configured")
		return

	webhook_url = f"{settings.public_base_url.rstrip('/')}/api/auth/telegram/webhook"
	secret = settings.telegram_webhook_secret or None

	try:
		async with httpx.AsyncClient(timeout=30.0) as client:
			response = await client.post(
				_api_url("setWebhook"),
				json={
					"url": webhook_url,
					"allowed_updates": ["message"],
					"secret_token": secret,
				},
			)
			payload = response.json()
			if payload.get("ok"):
				logger.info("Telegram webhook set to %s", webhook_url)
			else:
				logger.error("Failed to set Telegram webhook: %s", payload)
	except httpx.HTTPError as error:
		logger.warning("Telegram webhook setup skipped: %s", error)
