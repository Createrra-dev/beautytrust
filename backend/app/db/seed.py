from datetime import datetime, timedelta, timezone

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.config import settings
from app.db import models
from app.services.subscription_service import ensure_tariff_plans


def _now() -> datetime:
	return datetime.now(timezone.utc)


def _risk_level(rating: float) -> str:
	if rating >= 4:
		return "low"
	if rating >= 3:
		return "medium"
	return "high"


def seed_database(db: Session) -> None:
	ensure_tariff_plans(db)

	if db.scalar(select(models.Master).limit(1)):
		return

	master = models.Master(
		first_name="Анна",
		badge_label="Премиум мастер",
		rating=4.8,
		reviews_count=128,
		clients_count=247,
		prevented_no_shows=12,
		protected_income=156000,
		tariff_label="Бесплатно",
		tariff_plan_id="free",
	)
	db.add(master)
	db.flush()

	services = [
		("Маникюр + покрытие", "2 ч", 2500),
		("Стрижка и укладка", "1,5 ч", 3200),
		("Окрашивание", "3 ч", 5800),
		("Педикюр", "1,5 ч", 2800),
		("Брови + ламинирование", "1 ч", 1900),
		("Кератиновое выпрямление", "4 ч", 7500),
		("Макияж", "1,5 ч", 3500),
		("Наращивание ресниц", "2,5 ч", 4200),
	]
	for name, duration, price in services:
		db.add(
			models.MasterService(
				master_id=master.id,
				name=name,
				duration_label=duration,
				price=price,
			)
		)

	profiles = [
		("9992345678", "Анна", "Отличный", 4.9, 0, 0, "Клиент в целом надёжный", "Рекомендуем к записи"),
		("9991234567", "Екатерина", "Хороший", 4.2, 1, 0, "Клиент в целом надёжный", "Рекомендуем к записи"),
		("9998765432", "Ирина", "Ненадёжный", 1.8, 4, 1, "Клиент ненадёжный", "Рекомендуем отказать в записи"),
		("9165551234", "Клиент", "Средний", 3.1, 2, 0, "Клиент требует внимания", "Рекомендуем предоплату"),
		("9031112233", "Клиент", "Хороший", 4.5, 0, 0, "Клиент в целом надёжный", "Рекомендуем к записи"),
		("9254445566", "Клиент", "Средний", 3.8, 1, 0, "Клиент требует внимания", "Рекомендуем предоплату"),
	]
	profile_models: dict[str, models.ClientProfile] = {}
	for phone, name, label, rating, no_shows, scandals, title, subtitle in profiles:
		profile = models.ClientProfile(
			phone_digits=phone,
			client_name=name,
			rating_label=label,
			reviews_average=rating,
			reviews_count=2,
			no_shows_count=no_shows,
			scandals_count=scandals,
			reliability_title=title,
			reliability_subtitle=subtitle,
		)
		db.add(profile)
		db.flush()
		profile_models[phone] = profile
		db.add(
			models.MasterReview(
				client_profile_id=profile.id,
				author_name="Мария",
				rating=min(5.0, rating + 0.2),
				text="Клиент пришёл вовремя и оставил чаевые.",
				review_month=6,
				review_year=2026,
			)
		)

	today = _now().replace(hour=0, minute=0, second=0, microsecond=0)
	appointments = [
		("1", "Анна", "9992345678", "Маникюр + покрытие", "2 ч", 0, 10, 0, 2500, 4.9, 0),
		("2", "Мария", "9165551234", "Стрижка и укладка", "1,5 ч", 0, 14, 0, 3200, 3.4, 1),
		("3", "Екатерина", "9991234567", "Окрашивание", "3 ч", 1, 11, 0, 5800, 4.2, 0),
		("9", "Ирина", "9998765432", "Химическая завивка", "3,5 ч", 6, 13, 0, 6100, 1.8, 6),
	]
	for ext_id, name, phone, service, duration, day_offset, hour, minute, price, rating, verified in appointments:
		db.add(
			models.Appointment(
				external_id=ext_id,
				master_id=master.id,
				client_name=name,
				client_phone_digits=phone,
				service_name=service,
				service_duration_label=duration,
				scheduled_at=today + timedelta(days=day_offset, hours=hour, minutes=minute),
				service_price=price,
				client_rating=rating,
				risk_level=_risk_level(rating),
				days_since_verified=verified,
			)
		)

	topic = models.CommunityTopic(
		external_id="topic-1",
		title="Как брать предоплату с новых клиентов?",
		author_name="Мария",
		emoji="💳",
		is_pinned=True,
		participant_count=24,
		participant_initials="М,О,Е,А",
		last_message="Я прошу 30% при первой записи — работает отлично",
		last_message_at=_now() - timedelta(hours=2),
		unread_count=2,
	)
	db.add(topic)
	db.flush()
	db.add(
		models.CommunityMessage(
			external_id="m-1",
			topic_id=topic.id,
			author_name="Мария",
			text="Как вы работаете с новыми клиентами без истории?",
			sent_at=_now() - timedelta(days=1),
			is_mine=False,
		)
	)

	support_ticket = models.SupportTicket(
		external_id="support-1",
		master_id=master.id,
		title="Не обновляется рейтинг клиента",
		author_name=master.first_name,
		status="in_progress",
		last_message="Проверьте, пожалуйста, обновление после смены номера.",
		last_message_at=_now() - timedelta(hours=2),
	)
	db.add(support_ticket)
	db.flush()
	db.add(
		models.SupportMessage(
			external_id="s1-m1",
			ticket_id=support_ticket.id,
			author_name=master.first_name,
			text="После редактирования записи рейтинг не обновился.",
			sent_at=_now() - timedelta(days=1),
			is_mine=True,
		)
	)
	db.add(
		models.SupportMessage(
			external_id="s1-m2",
			ticket_id=support_ticket.id,
			author_name="Техподдержка",
			text="Мы уже проверяем сценарий обновления рейтинга.",
			sent_at=_now() - timedelta(hours=3),
			is_mine=False,
		)
	)

	db.commit()
