import json
from datetime import datetime, timezone

from sqlalchemy.orm import Session

from app.db import models


def create_notification(
	db: Session,
	*,
	master_id: int,
	title: str,
	body: str,
	kind: str = "general",
	payload: dict | None = None,
) -> models.AppNotification:
	notification = models.AppNotification(
		master_id=master_id,
		title=title.strip()[:200],
		body=body.strip(),
		kind=kind,
		payload_json=json.dumps(payload, ensure_ascii=False) if payload else None,
		is_read=False,
		created_at=datetime.now(timezone.utc),
	)
	db.add(notification)
	db.commit()
	db.refresh(notification)
	return notification


def notify_support_reply(db: Session, ticket: models.SupportTicket, reply_text: str) -> None:
	create_notification(
		db,
		master_id=ticket.master_id,
		title="Ответ поддержки",
		body=reply_text[:240],
		kind="support_reply",
		payload={"ticket_id": ticket.external_id},
	)
