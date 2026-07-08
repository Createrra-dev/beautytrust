from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db import models


def save_phone_telegram_link(db: Session, phone_digits: str, telegram_chat_id: int) -> None:
	link = db.scalar(
		select(models.PhoneTelegramLink).where(
			models.PhoneTelegramLink.phone_digits == phone_digits
		)
	)
	if link is None:
		link = models.PhoneTelegramLink(
			phone_digits=phone_digits,
			telegram_chat_id=telegram_chat_id,
		)
	else:
		link.telegram_chat_id = telegram_chat_id

	db.add(link)
	db.commit()


def get_chat_id_for_phone(db: Session, phone_digits: str) -> int | None:
	link = db.scalar(
		select(models.PhoneTelegramLink.telegram_chat_id).where(
			models.PhoneTelegramLink.phone_digits == phone_digits
		)
	)
	if link is not None:
		return link

	master = db.scalar(
		select(models.Master.telegram_chat_id).where(models.Master.phone_digits == phone_digits)
	)
	if master is not None:
		return master

	return db.scalar(
		select(models.OtpSession.telegram_chat_id)
		.where(models.OtpSession.phone_digits == phone_digits)
		.where(models.OtpSession.telegram_chat_id.is_not(None))
		.order_by(models.OtpSession.created_at.desc())
		.limit(1)
	)


def get_phone_for_chat_id(db: Session, chat_id: int) -> str | None:
	link = db.scalar(
		select(models.PhoneTelegramLink.phone_digits).where(
			models.PhoneTelegramLink.telegram_chat_id == chat_id
		)
	)
	if link is not None:
		return link

	master = db.scalar(
		select(models.Master.phone_digits).where(models.Master.telegram_chat_id == chat_id)
	)
	if master is not None:
		return master

	return db.scalar(
		select(models.OtpSession.phone_digits)
		.where(models.OtpSession.telegram_chat_id == chat_id)
		.order_by(models.OtpSession.created_at.desc())
		.limit(1)
	)
