#!/usr/bin/env python3
"""Наполнение демо-данными для мастера (записи, клиенты, отзывы).

Запуск (из корня backend или в контейнере /app):
  PYTHONPATH=. python scripts/seed_master_demo.py
  PYTHONPATH=. python scripts/seed_master_demo.py --phone 9851311610 --clear

В Docker:
  docker compose exec api sh -c "cd /app && PYTHONPATH=/app python scripts/seed_master_demo.py --phone 9851311610 --clear"
"""

from __future__ import annotations

import argparse
from datetime import datetime, timezone

from sqlalchemy import delete, select

from app.db import models
from app.db.session import SessionLocal
from app.services.client_rating_service import (
	apply_visit_result_to_client,
	get_or_create_client_profile,
	rating_label_for,
	recalculate_profile_aggregates,
	reliability_texts,
	risk_level_from_rating,
)
from app.services.client_rating_service import normalize_phone_digits

MASTER_PHONE_DEFAULT = "9851311610"
DEMO_PREFIX = "916200"

SERVICES = [
	("Маникюр + покрытие", "2 ч", 2500),
	("Стрижка и укладка", "1,5 ч", 3200),
	("Окрашивание", "3 ч", 5800),
	("Педикюр", "1,5 ч", 2800),
	("Брови + ламинирование", "1 ч", 1900),
	("Макияж", "1,5 ч", 3500),
]

# name, initial_rating, no_shows, scandals, review_author, review_rating, review_text
CLIENTS = [
	("Алина", 4.9, 0, 0, "Мария", 5.0, "Всегда вовремя, приятная клиентка."),
	("Виктория", 4.2, 0, 0, "Ольга", 4.3, "Оплата без задержек."),
	("Дарья", 3.1, 2, 0, "Ирина", 3.0, "Иногда опаздывает на 15–20 минут."),
	("Евгений", 2.4, 1, 1, "Светлана", 2.2, "Был конфликт из-за цены."),
	("Жанна", 4.6, 0, 0, "Наталья", 4.7, "Оставляет чаевые."),
	("Зоя", 3.8, 1, 0, "Анна", 3.9, "В целом надёжная."),
	("Илья", 4.0, 0, 0, "Екатерина", 4.1, "Вежливый клиент."),
	("Ксения", 1.9, 4, 2, "Мария", 1.8, "Несколько неявок подряд."),
	("Лариса", 4.5, 0, 0, "Ольга", 4.6, "Рекомендую к записи."),
	("Милана", 4.7, 0, 0, "Ирина", 4.8, "Пунктуальная."),
	("Нина", 3.3, 1, 0, "Светлана", 3.4, "Требует напоминания."),
	("Олег", 4.1, 0, 0, "Анна", 4.0, "Спокойный клиент."),
	("Полина", 2.8, 2, 1, "Наталья", 2.7, "Спорит по стоимости услуг."),
	("Регина", 4.8, 0, 0, "Екатерина", 4.9, "Один из лучших клиентов."),
	("София", 3.6, 0, 0, "Мария", 3.7, "Средняя надёжность."),
	("Тамара", 4.3, 0, 0, "Ольга", 4.4, "Приходит заранее."),
	("Ульяна", 2.1, 3, 0, "Ирина", 2.0, "Частые переносы."),
	("Фаина", 4.4, 0, 0, "Светлана", 4.5, "Оплачивает полностью."),
]

# day, hour, client_index (0-based), service_index, visit: None = scheduled
PAST_APPOINTMENTS = [
	(1, 10, 0, 0, ("onTime", True, False, True, "Отличный визит, всё вовремя.")),
	(1, 14, 1, 1, ("onTime", True, False, False, None)),
	(2, 11, 2, 2, ("late", True, False, False, "Опоздала на 20 минут.")),
	(3, 12, 3, 3, ("noShow", False, False, False, None)),
	(4, 10, 4, 4, ("onTime", True, False, True, "Оставила чаевые.")),
	(5, 15, 5, 0, ("onTime", True, True, False, "Был спор по доп. услуге.")),
	(6, 11, 6, 5, ("onTime", True, False, False, None)),
	(7, 13, 7, 1, ("onTime", False, False, False, "Оплата неполная.")),
	(7, 17, 8, 2, ("late", True, False, True, "Пришла с опозданием, но довольна.")),
]

FUTURE_APPOINTMENTS = [
	(8, 10, 9, 0),
	(8, 15, 10, 1),
	(10, 11, 11, 2),
	(12, 14, 12, 3),
	(15, 10, 13, 4),
	(18, 12, 14, 5),
	(22, 16, 15, 0),
	(25, 11, 16, 1),
	(28, 14, 17, 2),
]


def _risk_level(rating: float) -> str:
	return risk_level_from_rating(rating)


def _client_phone(index: int) -> str:
	return f"{DEMO_PREFIX}{index + 1:04d}"


def _scheduled_at(year: int, month: int, day: int, hour: int, minute: int = 0) -> datetime:
	return datetime(year, month, day, hour, minute, tzinfo=timezone.utc)


def _ensure_client(
	db,
	index: int,
	name: str,
	rating: float,
	no_shows: int,
	scandals: int,
	review_author: str,
	review_rating: float,
	review_text: str,
) -> models.ClientProfile:
	phone = _client_phone(index)
	profile = get_or_create_client_profile(db, phone, name)
	title, subtitle = reliability_texts(rating, no_shows, scandals)
	profile.client_name = name
	profile.reviews_average = rating
	profile.rating_label = rating_label_for(rating)
	profile.reviews_count = 1
	profile.no_shows_count = no_shows
	profile.scandals_count = scandals
	profile.reliability_title = title
	profile.reliability_subtitle = subtitle
	db.add(profile)
	db.flush()

	existing_review = db.scalar(
		select(models.MasterReview).where(
			models.MasterReview.client_profile_id == profile.id,
			models.MasterReview.appointment_id.is_(None),
		)
	)
	if existing_review is None:
		db.add(
			models.MasterReview(
				client_profile_id=profile.id,
				master_id=None,
				appointment_id=None,
				author_name=review_author,
				rating=review_rating,
				text=review_text,
				review_month=6,
				review_year=2026,
			)
		)
	db.flush()
	recalculate_profile_aggregates(db, profile)
	return profile


def _clear_demo_data(db, master_id: int) -> None:
	appointment_ids = db.scalars(
		select(models.Appointment.id).where(
			models.Appointment.master_id == master_id,
			models.Appointment.client_phone_digits.like(f"{DEMO_PREFIX}%"),
		)
	).all()
	if appointment_ids:
		db.execute(
			delete(models.VisitResult).where(
				models.VisitResult.appointment_id.in_(appointment_ids)
			)
		)
		db.execute(
			delete(models.MasterReview).where(
				models.MasterReview.appointment_id.in_(appointment_ids)
			)
		)
		db.execute(
			delete(models.Appointment).where(models.Appointment.id.in_(appointment_ids))
		)

	profiles = db.scalars(
		select(models.ClientProfile).where(models.ClientProfile.phone_digits.like(f"{DEMO_PREFIX}%"))
	).all()
	for profile in profiles:
		db.execute(
			delete(models.MasterReview).where(
				models.MasterReview.client_profile_id == profile.id
			)
		)
		db.execute(delete(models.ClientProfile).where(models.ClientProfile.id == profile.id))
	db.commit()


def _refresh_master_stats(db, master: models.Master) -> None:
	from sqlalchemy import func
	from sqlalchemy.orm import joinedload

	clients_count = db.scalar(
		select(func.count(func.distinct(models.Appointment.client_phone_digits))).where(
			models.Appointment.master_id == master.id,
		)
	) or 0

	appointments = db.scalars(
		select(models.Appointment)
		.options(joinedload(models.Appointment.visit_result))
		.where(models.Appointment.master_id == master.id)
	).unique().all()

	protected_income = 0
	prevented_no_shows = 0
	for appointment in appointments:
		if appointment.status != "completed":
			continue
		protected_income += appointment.service_price
		if appointment.risk_level == "high":
			prevented_no_shows += 1

	master.clients_count = int(clients_count)
	master.protected_income = protected_income
	master.prevented_no_shows = prevented_no_shows
	db.add(master)


def seed_master_demo(db, master: models.Master, *, clear: bool = False) -> dict[str, int]:
	if clear:
		_clear_demo_data(db, master.id)

	profiles: list[models.ClientProfile] = []
	for index, row in enumerate(CLIENTS):
		profiles.append(_ensure_client(db, index, *row))

	created_past = 0
	for day, hour, client_idx, service_idx, visit_data in PAST_APPOINTMENTS:
		punctuality, paid, scandal, tips, comment = visit_data
		client = profiles[client_idx]
		service = SERVICES[service_idx % len(SERVICES)]
		scheduled = _scheduled_at(2026, 7, day, hour)
		external_id = f"demo-{master.id}-past-{day}-{hour}-{client_idx}"

		existing = db.scalar(
			select(models.Appointment).where(models.Appointment.external_id == external_id)
		)
		if existing:
			continue

		appointment = models.Appointment(
			external_id=external_id,
			master_id=master.id,
			client_name=client.client_name,
			client_phone_digits=client.phone_digits,
			service_name=service[0],
			service_duration_label=service[1],
			scheduled_at=scheduled,
			service_price=service[2],
			client_rating=client.reviews_average,
			risk_level=_risk_level(client.reviews_average),
			status="scheduled",
			days_since_verified=0,
		)
		db.add(appointment)
		db.flush()

		visit = models.VisitResult(
			appointment_id=appointment.id,
			punctuality=punctuality,
			paid_in_full=paid,
			had_behavior_issues=scandal,
			had_scandal=scandal,
			left_tips=tips,
			comment=comment,
		)
		appointment.visit_result = visit
		db.flush()
		apply_visit_result_to_client(db, appointment, visit, master)
		created_past += 1

	created_future = 0
	for day, hour, client_idx, service_idx in FUTURE_APPOINTMENTS:
		client = profiles[client_idx]
		service = SERVICES[service_idx % len(SERVICES)]
		scheduled = _scheduled_at(2026, 7, day, hour)
		external_id = f"demo-{master.id}-future-{day}-{hour}-{client_idx}"

		existing = db.scalar(
			select(models.Appointment).where(models.Appointment.external_id == external_id)
		)
		if existing:
			continue

		db.add(
			models.Appointment(
				external_id=external_id,
				master_id=master.id,
				client_name=client.client_name,
				client_phone_digits=client.phone_digits,
				service_name=service[0],
				service_duration_label=service[1],
				scheduled_at=scheduled,
				service_price=service[2],
				client_rating=client.reviews_average,
				risk_level=_risk_level(client.reviews_average),
				status="scheduled",
				days_since_verified=0,
			)
		)
		created_future += 1

	_refresh_master_stats(db, master)
	db.commit()

	return {
		"clients": len(profiles),
		"past_appointments": created_past,
		"future_appointments": created_future,
	}


def main() -> None:
	parser = argparse.ArgumentParser(description="Seed demo appointments for a master")
	parser.add_argument("--phone", default=MASTER_PHONE_DEFAULT)
	parser.add_argument("--clear", action="store_true", help="Remove previous demo data first")
	args = parser.parse_args()

	phone_digits = normalize_phone_digits(args.phone)

	with SessionLocal() as db:
		master = db.scalar(select(models.Master).where(models.Master.phone_digits == phone_digits))
		if master is None:
			raise SystemExit(f"Master not found for phone {phone_digits}")

		result = seed_master_demo(db, master, clear=args.clear)
		print(
			f"OK master_id={master.id} ({master.first_name}): "
			f"clients={result['clients']}, "
			f"past={result['past_appointments']}, "
			f"future={result['future_appointments']}"
		)


if __name__ == "__main__":
	main()
