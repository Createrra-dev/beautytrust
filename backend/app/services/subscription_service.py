import json
from calendar import monthrange
from datetime import datetime, timezone
from typing import Any

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db import models

MAX_DISCOUNT_PERCENT = 30
MAX_DISCOUNT_MONTHS = 12

TARIFF_SEED = [
	{
		"id": "free",
		"title": "Бесплатно",
		"monthly_price": 0,
		"trial_label": "1 месяц бесплатно",
		"features": [
			"Проверка клиентов по номеру",
			"Отзывы мастеров",
			"Базовая аналитика",
			"Уведомления о рисках",
		],
		"card_button_label": "Попробовать бесплатно",
		"audience": "masters",
		"is_popular": False,
		"sort_order": 1,
	},
	{
		"id": "master",
		"title": "Мастер",
		"monthly_price": 799,
		"trial_label": "1 месяц бесплатно",
		"features": [
			"Проверка клиентов по номеру",
			"Отзывы мастеров",
			"Базовая аналитика",
			"Уведомления о рисках",
			"Приоритетная поддержка",
			"Экспорт данных",
		],
		"card_button_label": "Выбрать тариф",
		"audience": "masters",
		"is_popular": True,
		"sort_order": 2,
	},
	{
		"id": "studio",
		"title": "Студия",
		"monthly_price": 2490,
		"trial_label": "14 дней бесплатно",
		"features": [
			"До 5 мастеров в аккаунте",
			"Проверка клиентов по номеру",
			"Общая аналитика студии",
			"Уведомления о рисках",
		],
		"card_button_label": "Выбрать тариф",
		"audience": "studios",
		"is_popular": False,
		"sort_order": 3,
	},
	{
		"id": "studio_pro",
		"title": "Студия Pro",
		"monthly_price": 4990,
		"trial_label": "14 дней бесплатно",
		"features": [
			"Неограниченно мастеров",
			"Проверка клиентов по номеру",
			"Расширенная аналитика",
			"Приоритетная поддержка",
			"Экспорт данных",
		],
		"card_button_label": "Выбрать тариф",
		"audience": "studios",
		"is_popular": True,
		"sort_order": 4,
	},
]


def utc_now() -> datetime:
	return datetime.now(timezone.utc)


def discount_percent_for_months(months: int) -> int:
	if months <= 1:
		return 0
	if months >= MAX_DISCOUNT_MONTHS:
		return MAX_DISCOUNT_PERCENT
	progress = (months - 1) / (MAX_DISCOUNT_MONTHS - 1)
	return round(MAX_DISCOUNT_PERCENT * progress)


def quote_amount_kopecks(monthly_price_rubles: int, months: int) -> tuple[int, int, int]:
	base_total = monthly_price_rubles * months
	discount = discount_percent_for_months(months)
	total = round(base_total * (100 - discount) / 100)
	saved = base_total - total
	return total * 100, discount, saved * 100


def add_months(start: datetime, months: int) -> datetime:
	year = start.year + (start.month - 1 + months) // 12
	month = (start.month - 1 + months) % 12 + 1
	day = min(start.day, monthrange(year, month)[1])
	return start.replace(year=year, month=month, day=day)


def plan_features(plan: models.TariffPlan) -> list[str]:
	try:
		parsed = json.loads(plan.features_json or "[]")
		if isinstance(parsed, list):
			return [str(item) for item in parsed]
	except json.JSONDecodeError:
		pass
	return []


def ensure_tariff_plans(db: Session) -> None:
	existing = {
		plan.id: plan
		for plan in db.scalars(select(models.TariffPlan)).all()
	}
	changed = False
	for item in TARIFF_SEED:
		plan = existing.get(item["id"])
		payload = {
			"title": item["title"],
			"monthly_price": item["monthly_price"],
			"trial_label": item["trial_label"],
			"features_json": json.dumps(item["features"], ensure_ascii=False),
			"card_button_label": item["card_button_label"],
			"audience": item["audience"],
			"is_popular": item["is_popular"],
			"sort_order": item["sort_order"],
			"is_active": True,
		}
		if plan is None:
			db.add(models.TariffPlan(id=item["id"], **payload))
			changed = True
		else:
			for key, value in payload.items():
				if getattr(plan, key) != value:
					setattr(plan, key, value)
					changed = True
	if changed:
		db.commit()


def activate_subscription(
	db: Session,
	*,
	master: models.Master,
	plan: models.TariffPlan,
	months: int,
	amount: int,
	payment_attempt_id: int | None = None,
) -> models.SubscriptionPayment:
	now = utc_now()
	base = now
	if (
		master.tariff_plan_id == plan.id
		and master.tariff_expires_at is not None
		and master.tariff_expires_at > now
	):
		base = master.tariff_expires_at
		if base.tzinfo is None:
			base = base.replace(tzinfo=timezone.utc)

	expires_at = add_months(base, max(1, months))
	master.tariff_plan_id = plan.id
	master.tariff_label = plan.title
	master.tariff_expires_at = expires_at
	db.add(master)

	subscription = models.SubscriptionPayment(
		master_id=master.id,
		tariff_plan_id=plan.id,
		payment_attempt_id=payment_attempt_id,
		months=months,
		amount=amount,
		status="activated",
		activated_at=now,
		expires_at=expires_at,
	)
	db.add(subscription)
	db.commit()
	db.refresh(subscription)
	db.refresh(master)
	return subscription


def activate_from_payment_attempt(db: Session, attempt: models.PaymentAttempt) -> models.SubscriptionPayment | None:
	if not attempt.success:
		return None
	if attempt.master_id is None or attempt.tariff_plan_id is None:
		return None

	existing = db.scalar(
		select(models.SubscriptionPayment).where(
			models.SubscriptionPayment.payment_attempt_id == attempt.id,
			models.SubscriptionPayment.status == "activated",
		)
	)
	if existing is not None:
		return existing

	master = db.get(models.Master, attempt.master_id)
	plan = db.get(models.TariffPlan, attempt.tariff_plan_id)
	if master is None or plan is None:
		return None

	return activate_subscription(
		db,
		master=master,
		plan=plan,
		months=attempt.months or 1,
		amount=attempt.amount,
		payment_attempt_id=attempt.id,
	)


def subscription_payload(master: models.Master, plan: models.TariffPlan | None) -> dict[str, Any]:
	now = utc_now()
	expires = master.tariff_expires_at
	is_active = True
	if expires is not None:
		if expires.tzinfo is None:
			expires = expires.replace(tzinfo=timezone.utc)
		is_active = expires >= now

	return {
		"plan_id": master.tariff_plan_id or (plan.id if plan else "free"),
		"plan_title": (plan.title if plan else master.tariff_label),
		"tariff_label": master.tariff_label,
		"expires_at": expires.isoformat() if expires else None,
		"is_active": is_active and bool(master.tariff_plan_id or master.tariff_label),
		"monthly_price": plan.monthly_price if plan else 0,
	}
