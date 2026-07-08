import logging
from datetime import datetime, timezone

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db import models
from app.services.auth_service import deliver_otp_code, normalize_phone_digits
from app.services.telegram_bot import TelegramBotError, send_message
from app.services.telegram_link import get_phone_for_chat_id, save_phone_telegram_link

logger = logging.getLogger(__name__)


async def handle_telegram_update(db: Session, update: dict) -> None:
	try:
		await _handle_telegram_update(db, update)
	except Exception:
		logger.exception("Failed to process Telegram update: %s", update)


async def _handle_telegram_update(db: Session, update: dict) -> None:
	message = update.get("message")
	if message is None:
		return

	chat_id = message["chat"]["id"]
	text = (message.get("text") or "").strip()

	if text.startswith("/start"):
		payload = text.split(maxsplit=1)[1] if " " in text else ""
		await _handle_start(db, chat_id, payload)
		return

	contact = message.get("contact")
	if contact is not None:
		await _handle_contact(db, chat_id, contact)


async def _safe_send(chat_id: int, text: str) -> None:
	try:
		await send_message(chat_id, text)
	except TelegramBotError:
		logger.exception("Failed to send Telegram message to chat_id=%s", chat_id)


async def _find_active_session_for_chat(db: Session, chat_id: int) -> models.OtpSession | None:
	known_phone = get_phone_for_chat_id(db, chat_id)
	if known_phone is None:
		return None

	return db.scalar(
		select(models.OtpSession)
		.where(models.OtpSession.phone_digits == known_phone)
		.where(models.OtpSession.verified.is_(False))
		.where(models.OtpSession.expires_at > datetime.now(timezone.utc))
		.order_by(models.OtpSession.created_at.desc())
		.limit(1)
	)


async def _handle_start(db: Session, chat_id: int, payload: str) -> None:
	if not payload:
		active_session = await _find_active_session_for_chat(db, chat_id)
		if active_session is not None:
			active_session.telegram_chat_id = chat_id
			db.add(active_session)
			save_phone_telegram_link(db, active_session.phone_digits, chat_id)
			delivered = await deliver_otp_code(
				db,
				active_session,
				active_session.otp_code,
				telegram_chat_id=chat_id,
			)
			if delivered:
				await _safe_send(
					chat_id,
					"Код отправлен выше. Вернитесь в приложение Beauty Trust и введите его.",
				)
				return

		await _safe_send(
			chat_id,
			"<b>Beauty Trust</b>\n\n"
			"Сначала введите номер телефона в приложении и нажмите «Продолжить».\n\n"
			"Затем вернитесь сюда и нажмите /start — код придёт в этот чат.",
		)
		return

	if not payload.startswith("auth_"):
		await _safe_send(chat_id, "Ссылка устарела. Запросите новый код в приложении Beauty Trust.")
		return

	session_token = payload.removeprefix("auth_")
	session = db.scalar(
		select(models.OtpSession).where(models.OtpSession.session_token == session_token)
	)
	if session is None or session.verified:
		await _safe_send(
			chat_id,
			"Сессия не найдена или уже использована. Запросите новый код в приложении.",
		)
		return

	session.telegram_chat_id = chat_id
	db.add(session)
	save_phone_telegram_link(db, session.phone_digits, chat_id)

	delivered = await deliver_otp_code(db, session, session.otp_code, telegram_chat_id=chat_id)
	if delivered:
		await _safe_send(
			chat_id,
			"Код отправлен выше. Вернитесь в приложение и введите его.",
		)
	else:
		await _safe_send(chat_id, "Не удалось отправить код. Попробуйте позже.")


async def _handle_contact(db: Session, chat_id: int, contact: dict) -> None:
	raw_phone = contact.get("phone_number", "")
	try:
		phone_digits = normalize_phone_digits(raw_phone)
	except ValueError:
		await _safe_send(chat_id, "Не удалось распознать номер. Попробуйте снова через приложение.")
		return

	active_session = db.scalar(
		select(models.OtpSession)
		.where(models.OtpSession.phone_digits == phone_digits)
		.where(models.OtpSession.verified.is_(False))
		.where(models.OtpSession.expires_at > datetime.now(timezone.utc))
		.order_by(models.OtpSession.created_at.desc())
		.limit(1)
	)
	if active_session is not None:
		active_session.telegram_chat_id = chat_id
		db.add(active_session)
		save_phone_telegram_link(db, active_session.phone_digits, chat_id)
		delivered = await deliver_otp_code(
			db,
			active_session,
			active_session.otp_code,
			telegram_chat_id=chat_id,
		)
		if delivered:
			await _safe_send(chat_id, "Код отправлен. Вернитесь в приложение Beauty Trust.")
			return

	await _safe_send(
		chat_id,
		"Сначала запросите код входа в приложении Beauty Trust, затем снова нажмите /start.",
	)
