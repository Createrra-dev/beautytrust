import logging
import secrets
from datetime import datetime, timedelta, timezone

import jwt
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.config import settings
from app.db import models
from app.services.password_service import hash_password, normalize_email, validate_password
from app.services.telegram_bot import TelegramBotError, send_message
from app.services.telegram_link import get_chat_id_for_phone, save_phone_telegram_link
from app.services.zvonok_service import (
	OTP_CHANNEL_FLASH_CALL,
	OTP_CHANNEL_TELEGRAM,
	ZvonokError,
	initiate_flash_call,
)

logger = logging.getLogger(__name__)

OTP_LENGTH = 4
OTP_TTL_SECONDS = 300
MAX_VERIFY_ATTEMPTS = 5
VALID_OTP_CHANNELS = {OTP_CHANNEL_TELEGRAM, OTP_CHANNEL_FLASH_CALL}


def normalize_phone_digits(raw_phone: str) -> str:
	digits = "".join(character for character in raw_phone if character.isdigit())
	if digits.startswith("8") and len(digits) == 11:
		digits = digits[1:]
	if digits.startswith("7") and len(digits) == 11:
		digits = digits[1:]
	if len(digits) != 10:
		raise ValueError("Phone must contain 10 digits")
	return digits


def _generate_otp_code() -> str:
	upper_bound = 10 ** OTP_LENGTH
	return str(secrets.randbelow(upper_bound)).zfill(OTP_LENGTH)


def _bot_deep_link(session_token: str) -> str:
	username = settings.telegram_bot_username.lstrip("@")
	return f"https://t.me/{username}?start=auth_{session_token}"


def create_otp_session(
	db: Session,
	phone_digits: str,
	delivery_channel: str = OTP_CHANNEL_TELEGRAM,
	registration_first_name: str | None = None,
	registration_email: str | None = None,
	registration_password_hash: str | None = None,
) -> tuple[models.OtpSession, str]:
	if delivery_channel not in VALID_OTP_CHANNELS:
		raise ValueError("Unsupported OTP delivery channel")

	now = datetime.now(timezone.utc)
	old_sessions = db.scalars(
		select(models.OtpSession).where(
			models.OtpSession.phone_digits == phone_digits,
			models.OtpSession.verified.is_(False),
			models.OtpSession.expires_at > now,
		)
	).all()
	for old_session in old_sessions:
		old_session.expires_at = now
		db.add(old_session)

	session_token = secrets.token_urlsafe(24)
	otp_code = _generate_otp_code()
	expires_at = datetime.now(timezone.utc) + timedelta(seconds=OTP_TTL_SECONDS)

	session = models.OtpSession(
		session_token=session_token,
		phone_digits=phone_digits,
		otp_code=otp_code,
		delivery_channel=delivery_channel,
		expires_at=expires_at,
		registration_first_name=registration_first_name,
		registration_email=registration_email,
		registration_password_hash=registration_password_hash,
	)
	db.add(session)
	db.commit()
	db.refresh(session)
	return session, otp_code


async def deliver_otp_code(
	db: Session,
	session: models.OtpSession,
	otp_code: str,
	telegram_chat_id: int | None = None,
) -> bool:
	chat_id = telegram_chat_id or session.telegram_chat_id
	if chat_id is None:
		chat_id = get_chat_id_for_phone(db, session.phone_digits)

	if chat_id is None:
		return False

	phone_label = (
		f"+7 ({session.phone_digits[:3]}) {session.phone_digits[3:6]}-"
		f"{session.phone_digits[6:8]}-{session.phone_digits[8:10]}"
	)
	message = (
		f"<b>Beauty Trust</b>\n\n"
		f"Код для входа на номер {phone_label}:\n\n"
		f"<code>{otp_code}</code>\n\n"
		f"Код действует {OTP_TTL_SECONDS // 60} минут. Никому не сообщайте его."
	)

	try:
		await send_message(chat_id, message)
	except TelegramBotError:
		logger.exception("Failed to deliver OTP to chat_id=%s", chat_id)
		return False

	session.telegram_chat_id = chat_id
	session.delivered = True
	db.add(session)
	save_phone_telegram_link(db, session.phone_digits, chat_id)
	return True


async def deliver_otp_session(
	db: Session,
	session: models.OtpSession,
	otp_code: str,
) -> bool:
	if session.delivery_channel == OTP_CHANNEL_FLASH_CALL:
		flash_call_result = await initiate_flash_call(session.phone_digits)
		session.otp_code = flash_call_result.pincode
		session.zvonok_call_id = flash_call_result.call_id
		session.delivered = True
		db.add(session)
		db.commit()
		return True

	return await deliver_otp_code(db, session, otp_code)


def build_otp_send_response(session: models.OtpSession, code_sent: bool) -> dict[str, object]:
	return {
		"session_id": session.session_token,
		"bot_url": _bot_deep_link(session.session_token),
		"bot_username": settings.telegram_bot_username,
		"code_sent": code_sent,
		"expires_in": OTP_TTL_SECONDS,
		"channel": session.delivery_channel,
	}


def verify_otp_code(
	db: Session,
	session_token: str,
	code: str,
	first_name: str | None = None,
	email: str | None = None,
	password: str | None = None,
) -> models.Master:
	session = _resolve_session_for_verify(db, session_token, code)
	if session is None:
		raise ValueError("Сессия не найдена. Запросите код повторно.")

	if session.verified:
		raise ValueError("Код уже использован. Запросите новый.")
	if session.attempts >= MAX_VERIFY_ATTEMPTS:
		raise ValueError("Слишком много попыток. Запросите новый код.")

	session.attempts += 1
	db.add(session)
	db.commit()

	if code.strip() != session.otp_code:
		raise ValueError("Неверный код")

	session.verified = True
	db.add(session)

	master = db.scalar(
		select(models.Master).where(models.Master.phone_digits == session.phone_digits)
	)
	if master is None:
		display_name = first_name.strip() if first_name and first_name.strip() else session.registration_first_name
		if not display_name:
			display_name = "Мастер"

		master_email = normalize_email(email) if email else session.registration_email
		if master_email and email_is_registered(db, master_email):
			raise ValueError("Этот email уже используется")

		if password:
			validate_password(password)
			password_hash = hash_password(password)
		else:
			password_hash = session.registration_password_hash

		master = models.Master(
			first_name=display_name,
			badge_label="Новый мастер",
			rating=0.0,
			reviews_count=0,
			clients_count=0,
			prevented_no_shows=0,
			protected_income=0,
			tariff_label="Мастер",
			phone_digits=session.phone_digits,
			email=master_email,
			password_hash=password_hash,
		)
		db.add(master)
		db.flush()
	elif first_name and first_name.strip() and master.first_name == "Мастер":
		master.first_name = first_name.strip()
		db.add(master)

	if session.telegram_chat_id is not None:
		master.telegram_chat_id = session.telegram_chat_id
		save_phone_telegram_link(db, session.phone_digits, session.telegram_chat_id)

	db.commit()
	db.refresh(master)
	return master


def verify_otp_code_by_phone(
	db: Session,
	phone_digits: str,
	code: str,
	first_name: str | None = None,
	email: str | None = None,
	password: str | None = None,
) -> models.Master:
	session = _find_active_session_by_code(db, phone_digits, code.strip())
	if session is None:
		raise ValueError("Код истёк или неверный. Запросите новый в приложении.")
	return verify_otp_code(
		db,
		session.session_token,
		code,
		first_name=first_name,
		email=email,
		password=password,
	)


def phone_is_registered(db: Session, phone_digits: str) -> bool:
	master = db.scalar(
		select(models.Master).where(models.Master.phone_digits == phone_digits)
	)
	return master is not None


def email_is_registered(db: Session, email: str) -> bool:
	master = db.scalar(
		select(models.Master).where(models.Master.email == email)
	)
	return master is not None


def prepare_registration_data(
	db: Session,
	first_name: str | None,
	email: str | None,
	password: str | None,
) -> tuple[str, str | None, str]:
	if not first_name or not first_name.strip():
		raise ValueError("Укажите имя для регистрации")
	if not password:
		raise ValueError("Укажите пароль для регистрации")

	display_name = first_name.strip()
	normalized_email = normalize_email(email)
	if normalized_email and email_is_registered(db, normalized_email):
		raise ValueError("Этот email уже используется")

	password_hash = hash_password(password)
	return display_name, normalized_email, password_hash


def _resolve_session_for_verify(
	db: Session,
	session_token: str,
	code: str,
) -> models.OtpSession | None:
	session = db.scalar(
		select(models.OtpSession).where(models.OtpSession.session_token == session_token)
	)
	if session is None:
		return None

	now = datetime.now(timezone.utc)
	if session.expires_at > now and not session.verified:
		return session

	fallback_session = _find_active_session_by_code(db, session.phone_digits, code.strip())
	if fallback_session is not None:
		return fallback_session

	if session.expires_at <= now:
		raise ValueError("Код истёк. Нажмите «Отправить код повторно».")

	return session


def _find_active_session_by_code(
	db: Session,
	phone_digits: str,
	code: str,
) -> models.OtpSession | None:
	now = datetime.now(timezone.utc)
	sessions = db.scalars(
		select(models.OtpSession)
		.where(
			models.OtpSession.phone_digits == phone_digits,
			models.OtpSession.verified.is_(False),
			models.OtpSession.expires_at > now,
			models.OtpSession.otp_code == code,
		)
		.order_by(models.OtpSession.created_at.desc())
	).all()
	if not sessions:
		return None
	return sessions[0]


def create_access_token(master_id: int) -> str:
	expires_at = datetime.now(timezone.utc) + timedelta(minutes=settings.auth_access_token_minutes)
	payload = {
		"sub": str(master_id),
		"exp": expires_at,
		"iat": datetime.now(timezone.utc),
	}
	return jwt.encode(payload, settings.auth_jwt_secret, algorithm="HS256")
