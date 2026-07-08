from typing import Any
from uuid import uuid4

import httpx

from app.config import settings
from app.tbank.token import generate_token


class TBankClient:
	def __init__(self) -> None:
		self._api_url = settings.tbank_api_url.rstrip("/")

	async def init_payment(
		self,
		*,
		order_id: str | None = None,
		amount: int | None = None,
		description: str,
		success_url: str,
		fail_url: str,
		notification_url: str | None = None,
	) -> dict[str, Any]:
		payload: dict[str, Any] = {
			"TerminalKey": settings.tbank_terminal_key,
			"Amount": amount or settings.payment_amount_kopecks,
			"OrderId": order_id or f"order-{uuid4().hex[:16]}",
			"Description": description,
			"SuccessURL": success_url,
			"FailURL": fail_url,
			"Language": "ru",
		}
		if notification_url:
			payload["NotificationURL"] = notification_url
		payload["Token"] = generate_token(payload, settings.tbank_password)

		response = await httpx.AsyncClient(timeout=30.0).post(
			f"{self._api_url}/Init",
			json=payload,
		)
		response.raise_for_status()
		data = response.json()

		if not data.get("Success"):
			message = data.get("Message") or data.get("Details") or "Init failed"
			error_code = data.get("ErrorCode", "unknown")
			raise RuntimeError(f"T-Bank Init error {error_code}: {message}")

		return data

	async def get_payment_state(self, payment_id: str) -> dict[str, Any]:
		payload: dict[str, Any] = {
			"TerminalKey": settings.tbank_terminal_key,
			"PaymentId": payment_id,
		}
		payload["Token"] = generate_token(payload, settings.tbank_password)

		response = await httpx.AsyncClient(timeout=30.0).post(
			f"{self._api_url}/GetState",
			json=payload,
		)
		response.raise_for_status()
		data = response.json()

		if not data.get("Success"):
			message = data.get("Message") or data.get("Details") or "GetState failed"
			error_code = data.get("ErrorCode", "unknown")
			raise RuntimeError(f"T-Bank GetState error {error_code}: {message}")

		return data
