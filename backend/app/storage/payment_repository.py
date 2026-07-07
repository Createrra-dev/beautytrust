import json
from datetime import datetime, timezone
from typing import Any

from app.storage.database import get_connection


def _utc_now() -> str:
	return datetime.now(timezone.utc).isoformat()


def _row_to_dict(row) -> dict[str, Any]:
	data = dict(row)
	data["success"] = bool(data["success"])
	if data.get("tbank_response"):
		try:
			data["tbank_response"] = json.loads(data["tbank_response"])
		except json.JSONDecodeError:
			pass
	return data


class PaymentRepository:
	def create_attempt(
		self,
		*,
		order_id: str,
		amount: int,
		description: str,
		status: str = "CREATED",
	) -> dict[str, Any]:
		now = _utc_now()
		with get_connection() as connection:
			cursor = connection.execute(
				"""
				INSERT INTO payment_attempts (
					order_id, amount, description, status, success,
					created_at, updated_at
				) VALUES (?, ?, ?, ?, 0, ?, ?)
				""",
				(order_id, amount, description, status, now, now),
			)
			connection.commit()
			attempt_id = cursor.lastrowid

		return self.get_by_id(attempt_id)

	def mark_init_success(
		self,
		attempt_id: int,
		*,
		payment_id: str,
		payment_url: str,
		tbank_response: dict[str, Any],
	) -> dict[str, Any]:
		now = _utc_now()
		with get_connection() as connection:
			connection.execute(
				"""
				UPDATE payment_attempts
				SET payment_id = ?, payment_url = ?, status = ?, success = 0,
					last_error = NULL, tbank_response = ?, updated_at = ?
				WHERE id = ?
				""",
				(
					payment_id,
					payment_url,
					"NEW",
					json.dumps(tbank_response, ensure_ascii=False),
					now,
					attempt_id,
				),
			)
			connection.commit()

		return self.get_by_id(attempt_id)

	def mark_init_failed(
		self,
		attempt_id: int,
		*,
		error_message: str,
	) -> dict[str, Any]:
		now = _utc_now()
		with get_connection() as connection:
			connection.execute(
				"""
				UPDATE payment_attempts
				SET status = ?, success = 0, last_error = ?, updated_at = ?
				WHERE id = ?
				""",
				("INIT_FAILED", error_message, now, attempt_id),
			)
			connection.commit()

		return self.get_by_id(attempt_id)

	def update_from_tbank(
		self,
		*,
		payment_id: str,
		status: str,
		success: bool,
		tbank_response: dict[str, Any],
		last_error: str | None = None,
	) -> dict[str, Any] | None:
		now = _utc_now()
		with get_connection() as connection:
			cursor = connection.execute(
				"""
				UPDATE payment_attempts
				SET status = ?, success = ?, tbank_response = ?,
					last_error = ?, updated_at = ?
				WHERE payment_id = ?
				""",
				(
					status,
					int(success),
					json.dumps(tbank_response, ensure_ascii=False),
					last_error,
					now,
					payment_id,
				),
			)
			connection.commit()
			if cursor.rowcount == 0:
				return None

		return self.get_by_payment_id(payment_id)

	def mark_return_result(
		self,
		*,
		order_id: str | None = None,
		payment_id: str | None = None,
		return_result: str,
	) -> dict[str, Any] | None:
		now = _utc_now()
		query = """
			UPDATE payment_attempts
			SET return_result = ?, updated_at = ?
			WHERE {field} = ?
		"""
		field_value: tuple[str, str] | None = None

		if payment_id:
			field_value = ("payment_id", payment_id)
		elif order_id:
			field_value = ("order_id", order_id)

		if field_value is None:
			return None

		field_name, field_val = field_value
		with get_connection() as connection:
			cursor = connection.execute(
				query.format(field=field_name),
				(return_result, now, field_val),
			)
			connection.commit()
			if cursor.rowcount == 0:
				return None

		if payment_id:
			return self.get_by_payment_id(payment_id)
		return self.get_by_order_id(order_id)

	def get_by_id(self, attempt_id: int) -> dict[str, Any]:
		with get_connection() as connection:
			row = connection.execute(
				"SELECT * FROM payment_attempts WHERE id = ?",
				(attempt_id,),
			).fetchone()
		if row is None:
			raise KeyError(f"Payment attempt {attempt_id} not found")
		return _row_to_dict(row)

	def get_by_payment_id(self, payment_id: str) -> dict[str, Any] | None:
		with get_connection() as connection:
			row = connection.execute(
				"""
				SELECT * FROM payment_attempts
				WHERE payment_id = ?
				ORDER BY id DESC
				LIMIT 1
				""",
				(payment_id,),
			).fetchone()
		return _row_to_dict(row) if row else None

	def get_by_order_id(self, order_id: str) -> dict[str, Any] | None:
		with get_connection() as connection:
			row = connection.execute(
				"""
				SELECT * FROM payment_attempts
				WHERE order_id = ?
				ORDER BY id DESC
				LIMIT 1
				""",
				(order_id,),
			).fetchone()
		return _row_to_dict(row) if row else None

	def list_all(self, limit: int = 200) -> list[dict[str, Any]]:
		with get_connection() as connection:
			rows = connection.execute(
				"""
				SELECT * FROM payment_attempts
				ORDER BY created_at DESC
				LIMIT ?
				""",
				(limit,),
			).fetchall()
		return [_row_to_dict(row) for row in rows]

	def list_refreshable(self, limit: int = 200) -> list[dict[str, Any]]:
		with get_connection() as connection:
			rows = connection.execute(
				"""
				SELECT * FROM payment_attempts
				WHERE payment_id IS NOT NULL
				AND status NOT IN ('CONFIRMED', 'REJECTED', 'REVERSED', 'REFUNDED', 'DEADLINE_EXPIRED', 'INIT_FAILED')
				ORDER BY created_at DESC
				LIMIT ?
				""",
				(limit,),
			).fetchall()
		return [_row_to_dict(row) for row in rows]
