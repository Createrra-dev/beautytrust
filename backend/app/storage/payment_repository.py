import json
from datetime import datetime, timezone
from typing import Any

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db import models
from app.db.session import SessionLocal

FINAL_STATUSES = {
	"CONFIRMED",
	"REJECTED",
	"REVERSED",
	"REFUNDED",
	"DEADLINE_EXPIRED",
	"INIT_FAILED",
}


def _utc_now() -> datetime:
	return datetime.now(timezone.utc)


def _attempt_to_dict(attempt: models.PaymentAttempt) -> dict[str, Any]:
	tbank_response: Any = attempt.tbank_response
	if isinstance(tbank_response, str) and tbank_response:
		try:
			tbank_response = json.loads(tbank_response)
		except json.JSONDecodeError:
			pass

	created_at = attempt.created_at.isoformat() if attempt.created_at else None
	updated_at = attempt.updated_at.isoformat() if attempt.updated_at else None

	return {
		"id": attempt.id,
		"payment_id": attempt.payment_id,
		"order_id": attempt.order_id,
		"amount": attempt.amount,
		"description": attempt.description,
		"status": attempt.status,
		"success": bool(attempt.success),
		"payment_url": attempt.payment_url,
		"return_result": attempt.return_result,
		"last_error": attempt.last_error,
		"tbank_response": tbank_response,
		"master_id": attempt.master_id,
		"tariff_plan_id": attempt.tariff_plan_id,
		"months": attempt.months,
		"created_at": created_at,
		"updated_at": updated_at,
	}


class PaymentRepository:
	def _session(self) -> Session:
		return SessionLocal()

	def create_attempt(
		self,
		*,
		order_id: str,
		amount: int,
		description: str,
		status: str = "CREATED",
		master_id: int | None = None,
		tariff_plan_id: str | None = None,
		months: int | None = None,
	) -> dict[str, Any]:
		now = _utc_now()
		with self._session() as db:
			attempt = models.PaymentAttempt(
				order_id=order_id,
				amount=amount,
				description=description,
				status=status,
				success=False,
				master_id=master_id,
				tariff_plan_id=tariff_plan_id,
				months=months,
				created_at=now,
				updated_at=now,
			)
			db.add(attempt)
			db.commit()
			db.refresh(attempt)
			return _attempt_to_dict(attempt)

	def mark_init_success(
		self,
		attempt_id: int,
		*,
		payment_id: str,
		payment_url: str,
		tbank_response: dict[str, Any],
	) -> dict[str, Any]:
		with self._session() as db:
			attempt = db.get(models.PaymentAttempt, attempt_id)
			if attempt is None:
				raise KeyError(f"Payment attempt {attempt_id} not found")

			attempt.payment_id = payment_id
			attempt.payment_url = payment_url
			attempt.status = "NEW"
			attempt.success = False
			attempt.last_error = None
			attempt.tbank_response = json.dumps(tbank_response, ensure_ascii=False)
			attempt.updated_at = _utc_now()
			db.add(attempt)
			db.commit()
			db.refresh(attempt)
			return _attempt_to_dict(attempt)

	def mark_init_failed(
		self,
		attempt_id: int,
		*,
		error_message: str,
	) -> dict[str, Any]:
		with self._session() as db:
			attempt = db.get(models.PaymentAttempt, attempt_id)
			if attempt is None:
				raise KeyError(f"Payment attempt {attempt_id} not found")

			attempt.status = "INIT_FAILED"
			attempt.success = False
			attempt.last_error = error_message
			attempt.updated_at = _utc_now()
			db.add(attempt)
			db.commit()
			db.refresh(attempt)
			return _attempt_to_dict(attempt)

	def update_from_tbank(
		self,
		*,
		payment_id: str,
		status: str,
		success: bool,
		tbank_response: dict[str, Any],
		last_error: str | None = None,
	) -> dict[str, Any] | None:
		with self._session() as db:
			attempt = db.scalar(
				select(models.PaymentAttempt)
				.where(models.PaymentAttempt.payment_id == payment_id)
				.order_by(models.PaymentAttempt.id.desc())
			)
			if attempt is None:
				return None

			attempt.status = status
			attempt.success = success
			attempt.tbank_response = json.dumps(tbank_response, ensure_ascii=False)
			attempt.last_error = last_error
			attempt.updated_at = _utc_now()
			db.add(attempt)
			db.commit()
			db.refresh(attempt)
			return _attempt_to_dict(attempt)

	def mark_return_result(
		self,
		*,
		order_id: str | None = None,
		payment_id: str | None = None,
		return_result: str,
	) -> dict[str, Any] | None:
		with self._session() as db:
			query = select(models.PaymentAttempt)
			if payment_id:
				query = query.where(models.PaymentAttempt.payment_id == payment_id)
			elif order_id:
				query = query.where(models.PaymentAttempt.order_id == order_id)
			else:
				return None

			attempt = db.scalar(query.order_by(models.PaymentAttempt.id.desc()))
			if attempt is None:
				return None

			attempt.return_result = return_result
			attempt.updated_at = _utc_now()
			db.add(attempt)
			db.commit()
			db.refresh(attempt)
			return _attempt_to_dict(attempt)

	def get_by_id(self, attempt_id: int) -> dict[str, Any]:
		with self._session() as db:
			attempt = db.get(models.PaymentAttempt, attempt_id)
			if attempt is None:
				raise KeyError(f"Payment attempt {attempt_id} not found")
			return _attempt_to_dict(attempt)

	def get_by_payment_id(self, payment_id: str) -> dict[str, Any] | None:
		with self._session() as db:
			attempt = db.scalar(
				select(models.PaymentAttempt)
				.where(models.PaymentAttempt.payment_id == payment_id)
				.order_by(models.PaymentAttempt.id.desc())
			)
			return _attempt_to_dict(attempt) if attempt else None

	def get_by_order_id(self, order_id: str) -> dict[str, Any] | None:
		with self._session() as db:
			attempt = db.scalar(
				select(models.PaymentAttempt)
				.where(models.PaymentAttempt.order_id == order_id)
				.order_by(models.PaymentAttempt.id.desc())
			)
			return _attempt_to_dict(attempt) if attempt else None

	def list_all(self, limit: int = 200) -> list[dict[str, Any]]:
		with self._session() as db:
			attempts = db.scalars(
				select(models.PaymentAttempt)
				.order_by(models.PaymentAttempt.created_at.desc())
				.limit(limit)
			).all()
			return [_attempt_to_dict(item) for item in attempts]

	def list_refreshable(self, limit: int = 200) -> list[dict[str, Any]]:
		with self._session() as db:
			attempts = db.scalars(
				select(models.PaymentAttempt)
				.where(
					models.PaymentAttempt.payment_id.is_not(None),
					models.PaymentAttempt.status.not_in(FINAL_STATUSES),
				)
				.order_by(models.PaymentAttempt.created_at.desc())
				.limit(limit)
			).all()
			return [_attempt_to_dict(item) for item in attempts]
