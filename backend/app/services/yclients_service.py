from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from typing import Any
from zoneinfo import ZoneInfo

import httpx
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db import models
from app.services.client_rating_service import (
	days_since_last_check,
	get_or_create_client_profile,
	normalize_phone_digits,
	risk_level_from_rating,
)

YCLIENTS_API_BASE = "https://api.yclients.com/api/v1"
MOSCOW_TZ = ZoneInfo("Europe/Moscow")


class YClientsError(Exception):
	def __init__(self, message: str) -> None:
		super().__init__(message)
		self.message = message


def _headers(partner_token: str, user_token: str | None = None) -> dict[str, str]:
	auth = f"Bearer {partner_token}"
	if user_token:
		auth = f"{auth}, User {user_token}"
	return {
		"Accept": "application/vnd.api.v2+json",
		"Content-Type": "application/json",
		"Authorization": auth,
	}


@dataclass
class YClientsAuthResult:
	user_token: str | None = None
	auth_pending: bool = False
	auth_uuid: str | None = None
	auth_recipient: str | None = None
	auth_attempts_left: int | None = None


def _extract_auth_error(payload: dict[str, Any]) -> str:
	return (payload.get("meta") or {}).get("message") or "Ошибка авторизации YClients"


def _parse_auth_response(payload: dict[str, Any]) -> YClientsAuthResult:
	data = payload.get("data") or {}
	user_token = data.get("user_token")
	if user_token:
		return YClientsAuthResult(user_token=str(user_token))

	auth_uuid = data.get("uuid")
	if auth_uuid:
		transport = data.get("transport") or {}
		return YClientsAuthResult(
			auth_pending=True,
			auth_uuid=str(auth_uuid),
			auth_recipient=str(transport.get("recipient") or "").strip() or None,
			auth_attempts_left=data.get("attempts_left"),
		)

	raise YClientsError(_extract_auth_error(payload))


def authenticate_user(partner_token: str, login: str, password: str) -> YClientsAuthResult:
	response = httpx.post(
		f"{YCLIENTS_API_BASE}/auth",
		headers=_headers(partner_token),
		json={"login": login, "password": password},
		timeout=30.0,
	)
	payload = response.json()
	if response.status_code >= 400 or not payload.get("success"):
		raise YClientsError(_extract_auth_error(payload))
	return _parse_auth_response(payload)


def confirm_authentication(
	partner_token: str,
	login: str,
	password: str,
	auth_code: str,
	*,
	uuid: str | None = None,
) -> str:
	body: dict[str, str] = {
		"login": login,
		"password": password,
		"code": auth_code.strip(),
	}
	if uuid:
		body["uuid"] = uuid

	response = httpx.post(
		f"{YCLIENTS_API_BASE}/auth",
		headers=_headers(partner_token),
		json=body,
		timeout=30.0,
	)
	payload = response.json()
	if response.status_code >= 400 or not payload.get("success"):
		raise YClientsError(_extract_auth_error(payload))

	result = _parse_auth_response(payload)
	if result.user_token:
		return result.user_token
	raise YClientsError("YClients не принял код подтверждения")


def fetch_records(
	partner_token: str,
	user_token: str,
	company_id: str,
	*,
	start_date: str,
	end_date: str | None = None,
) -> list[dict[str, Any]]:
	records: list[dict[str, Any]] = []
	page = 1

	while True:
		params: dict[str, str | int] = {
			"page": page,
			"count": 200,
			"start_date": start_date,
		}
		if end_date:
			params["end_date"] = end_date

		response = httpx.get(
			f"{YCLIENTS_API_BASE}/records/{company_id}",
			headers=_headers(partner_token, user_token),
			params=params,
			timeout=30.0,
		)
		payload = response.json()
		if response.status_code >= 400 or not payload.get("success"):
			message = (payload.get("meta") or {}).get("message") or "Не удалось получить записи YClients"
			raise YClientsError(message)

		batch = payload.get("data") or []
		if not batch:
			break

		records.extend(batch)
		if len(batch) < 200:
			break
		page += 1

	return records


def _format_duration_label(seconds: int | None) -> str:
	if not seconds or seconds <= 0:
		return "1 ч"
	minutes = max(15, round(seconds / 60 / 15) * 15)
	if minutes % 60 == 0:
		hours = minutes // 60
		return f"{hours} ч"
	hours = minutes // 60
	rest = minutes % 60
	if hours == 0:
		return f"{rest} мин"
	if rest == 0:
		return f"{hours} ч"
	if rest == 30:
		return f"{hours},5 ч"
	return f"{hours} ч {rest} мин"


def _parse_record_datetime(record: dict[str, Any]) -> datetime | None:
	datetime_value = record.get("datetime")
	if isinstance(datetime_value, (int, float)) and datetime_value > 0:
		return datetime.fromtimestamp(datetime_value, tz=MOSCOW_TZ).astimezone(timezone.utc)

	date_value = record.get("date")
	if isinstance(date_value, (int, float)) and date_value > 0:
		return datetime.fromtimestamp(date_value, tz=MOSCOW_TZ).astimezone(timezone.utc)

	return None


def _extract_client(record: dict[str, Any]) -> tuple[str, str]:
	client = record.get("client") or {}
	name = (
		client.get("name")
		or client.get("display_name")
		or record.get("client_name")
		or "Клиент"
	)
	phone_raw = client.get("phone") or record.get("client_phone") or ""
	digits = "".join(char for char in str(phone_raw) if char.isdigit())
	if len(digits) == 11 and digits.startswith("7"):
		digits = digits[1:]
	if len(digits) != 10:
		raise ValueError("invalid phone")
	return str(name).strip()[:120], digits


def _extract_service(record: dict[str, Any]) -> tuple[str, int, int]:
	services = record.get("services") or []
	if not services:
		return "Услуга YClients", 0, record.get("seance_length") or record.get("length") or 3600

	titles: list[str] = []
	total_price = 0
	total_length = 0
	for service in services:
		title = str(service.get("title") or "Услуга").strip()
		titles.append(title)
		cost = service.get("cost") or service.get("manual_cost") or 0
		total_price += int(cost)
		length = service.get("length") or service.get("seance_length")
		if isinstance(length, (int, float)):
			total_length += int(length)

	service_name = ", ".join(titles)[:200]
	if total_length <= 0:
		total_length = record.get("seance_length") or record.get("length") or 3600
	return service_name, total_price, int(total_length)


def sync_yclients_appointments(db: Session, master: models.Master) -> dict[str, int]:
	if not master.yclients_enabled:
		return {"imported": 0, "updated": 0, "skipped": 0}

	partner_token = (master.yclients_partner_token or "").strip()
	company_id = (master.yclients_company_id or "").strip()
	user_token = (master.yclients_user_token or "").strip()
	if not partner_token or not company_id or not user_token:
		raise YClientsError("Заполните Partner Token, Company ID и выполните авторизацию YClients")

	now_utc = datetime.now(timezone.utc)
	now_moscow = now_utc.astimezone(MOSCOW_TZ)
	start_date = now_moscow.date().isoformat()
	end_date = (now_moscow.date() + timedelta(days=90)).isoformat()

	records = fetch_records(
		partner_token,
		user_token,
		company_id,
		start_date=start_date,
		end_date=end_date,
	)

	imported = 0
	updated = 0
	skipped = 0

	for record in records:
		if record.get("deleted"):
			skipped += 1
			continue

		scheduled_at = _parse_record_datetime(record)
		if scheduled_at is None or scheduled_at < now_utc:
			skipped += 1
			continue

		try:
			client_name, phone_digits = _extract_client(record)
		except ValueError:
			skipped += 1
			continue

		service_name, service_price, seance_length = _extract_service(record)
		staff = record.get("staff") or {}
		staff_name = str(staff.get("name") or "").strip()[:120] or None
		record_id = str(record.get("id") or "").strip()
		if not record_id:
			skipped += 1
			continue

		profile = get_or_create_client_profile(db, phone_digits, client_name)
		client_rating = profile.reviews_average
		risk_level = risk_level_from_rating(client_rating)
		days_since_verified = days_since_last_check(db, phone_digits)
		duration_label = _format_duration_label(seance_length)
		external_id = f"yclients-{master.id}-{record_id}"

		appointment = db.scalar(
			select(models.Appointment).where(
				models.Appointment.master_id == master.id,
				models.Appointment.yclients_record_id == record_id,
			)
		)
		if appointment is None:
			appointment = db.scalar(
				select(models.Appointment).where(
					models.Appointment.external_id == external_id,
				)
			)

		if appointment is None:
			appointment = models.Appointment(
				external_id=external_id,
				master_id=master.id,
				client_name=client_name,
				client_phone_digits=phone_digits,
				service_name=service_name,
				service_duration_label=duration_label,
				scheduled_at=scheduled_at,
				service_price=service_price,
				client_rating=client_rating,
				risk_level=risk_level,
				status="scheduled",
				days_since_verified=days_since_verified,
				source="yclients",
				yclients_record_id=record_id,
				yclients_staff_name=staff_name,
			)
			db.add(appointment)
			imported += 1
			continue

		appointment.client_name = client_name
		appointment.client_phone_digits = phone_digits
		appointment.service_name = service_name
		appointment.service_duration_label = duration_label
		appointment.scheduled_at = scheduled_at
		appointment.service_price = service_price
		appointment.client_rating = client_rating
		appointment.risk_level = risk_level
		appointment.days_since_verified = days_since_verified
		appointment.source = "yclients"
		appointment.yclients_record_id = record_id
		appointment.yclients_staff_name = staff_name
		db.add(appointment)
		updated += 1

	master.yclients_last_sync_at = now_utc
	master.yclients_last_sync_count = imported + updated
	db.add(master)
	db.commit()

	return {"imported": imported, "updated": updated, "skipped": skipped}


def yclients_integration_schema(master: models.Master) -> dict[str, Any]:
	return {
		"enabled": master.yclients_enabled,
		"partner_token": master.yclients_partner_token or "",
		"company_id": master.yclients_company_id or "",
		"login": master.yclients_login or "",
		"has_user_token": bool(master.yclients_user_token),
		"auth_pending": bool(master.yclients_auth_uuid),
		"auth_recipient": master.yclients_auth_recipient or "",
		"last_sync_at": master.yclients_last_sync_at,
		"last_sync_count": master.yclients_last_sync_count,
	}
