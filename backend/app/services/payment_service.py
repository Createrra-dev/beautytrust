from typing import Any

from app.storage.payment_repository import PaymentRepository
from app.tbank.client import TBankClient

SUCCESS_STATUSES = {"CONFIRMED", "AUTHORIZED"}
FINAL_STATUSES = {
	"CONFIRMED",
	"REJECTED",
	"REVERSED",
	"REFUNDED",
	"DEADLINE_EXPIRED",
	"INIT_FAILED",
}


class PaymentService:
	def __init__(
		self,
		repository: PaymentRepository | None = None,
		tbank_client: TBankClient | None = None,
	) -> None:
		self._repository = repository or PaymentRepository()
		self._tbank_client = tbank_client or TBankClient()

	@property
	def repository(self) -> PaymentRepository:
		return self._repository

	@staticmethod
	def parse_tbank_status(data: dict[str, Any]) -> tuple[str, bool]:
		status = str(data.get("Status") or "UNKNOWN")
		success = status in SUCCESS_STATUSES
		return status, success

	async def refresh_payment_status(self, payment_id: str) -> dict[str, Any]:
		try:
			result = await self._tbank_client.get_payment_state(payment_id)
		except Exception as error:
			existing = self._repository.get_by_payment_id(payment_id)
			if existing:
				self._repository.update_from_tbank(
					payment_id=payment_id,
					status=str(existing["status"]),
					success=bool(existing["success"]),
					tbank_response=existing.get("tbank_response") or {},
					last_error=str(error),
				)
			raise

		status, success = self.parse_tbank_status(result)
		updated = self._repository.update_from_tbank(
			payment_id=payment_id,
			status=status,
			success=success,
			tbank_response=result,
		)
		if updated is None:
			raise KeyError(f"Payment attempt with payment_id={payment_id} not found")

		return updated

	async def refresh_all_pending(self) -> list[dict[str, Any]]:
		attempts = self._repository.list_refreshable()
		refreshed: list[dict[str, Any]] = []

		for attempt in attempts:
			payment_id = attempt.get("payment_id")
			if not payment_id:
				continue

			try:
				refreshed.append(await self.refresh_payment_status(str(payment_id)))
			except Exception as error:
				attempt = self._repository.get_by_payment_id(str(payment_id)) or attempt
				attempt["refresh_error"] = str(error)
				refreshed.append(attempt)

		return refreshed

	async def init_payment(
		self,
		*,
		order_id: str,
		description: str,
		success_url: str,
		fail_url: str,
		amount: int | None = None,
	) -> dict[str, Any]:
		return await self._tbank_client.init_payment(
			order_id=order_id,
			amount=amount,
			description=description,
			success_url=success_url,
			fail_url=fail_url,
		)
