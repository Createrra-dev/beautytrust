from datetime import datetime, timezone

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.db import models


def risk_level_from_rating(rating: float) -> str:
	if rating >= 4:
		return "low"
	if rating >= 3:
		return "medium"
	return "high"


def rating_label_for(rating: float) -> str:
	if rating >= 4.5:
		return "Отличный"
	if rating >= 4:
		return "Хороший"
	if rating >= 3:
		return "Средний"
	return "Ненадёжный"


def reliability_texts(
	rating: float,
	no_shows: int,
	scandals: int,
) -> tuple[str, str]:
	if rating >= 4 and no_shows == 0 and scandals == 0:
		return "Клиент в целом надёжный", "Рекомендуем к записи"
	if rating < 3 or no_shows >= 3 or scandals >= 2:
		return "Клиент ненадёжный", "Рекомендуем отказать в записи"
	return "Клиент требует внимания", "Рекомендуем предоплату"


def visit_result_rating(
	punctuality: str,
	paid_in_full: bool,
	had_behavior_issues: bool,
	was_unfriendly: bool,
	had_scandal: bool,
	threatened_complaints: bool,
	demanded_discount: bool,
	stole_from_salon: bool,
	left_tips: bool,
) -> float:
	if punctuality == "noShow":
		return 1.5

	score = 4.0
	if punctuality == "onTime":
		score += 0.5
	elif punctuality == "late":
		score -= 0.5

	if paid_in_full:
		score += 0.3
	else:
		score -= 1.0

	if had_behavior_issues:
		score -= 0.8
		if was_unfriendly:
			score -= 0.3
		if had_scandal:
			score -= 0.8
		if threatened_complaints:
			score -= 1.0
		if demanded_discount:
			score -= 0.5
		if stole_from_salon:
			score -= 1.5

	if left_tips:
		score += 0.2

	return round(max(1.0, min(5.0, score)), 1)


def normalize_phone_digits(phone: str) -> str:
	digits = "".join(char for char in phone if char.isdigit())
	if len(digits) == 11 and digits.startswith("7"):
		digits = digits[1:]
	if len(digits) != 10:
		raise ValueError("Invalid phone number")
	return digits


def days_since_last_check(db: Session, phone_digits: str) -> int:
	last_checked = db.scalar(
		select(func.max(models.CheckHistoryRecord.checked_at)).where(
			models.CheckHistoryRecord.phone_digits == phone_digits,
		)
	)
	if last_checked is None:
		return 0

	now = datetime.now(timezone.utc)
	if last_checked.tzinfo is None:
		last_checked = last_checked.replace(tzinfo=timezone.utc)

	return max(0, (now - last_checked).days)


def get_or_create_client_profile(
	db: Session,
	phone_digits: str,
	client_name: str,
) -> models.ClientProfile:
	profile = db.scalar(
		select(models.ClientProfile).where(
			models.ClientProfile.phone_digits == phone_digits,
		)
	)
	if profile is None:
		profile = models.ClientProfile(
			phone_digits=phone_digits,
			client_name=client_name,
			rating_label="Средний",
			reviews_average=3.5,
			reviews_count=0,
			no_shows_count=0,
			scandals_count=0,
			reliability_title="Клиент требует внимания",
			reliability_subtitle="Рекомендуем предоплату",
		)
		db.add(profile)
		db.flush()
	elif client_name and profile.client_name != client_name:
		profile.client_name = client_name

	return profile


def _visit_review_text(visit: models.VisitResult) -> str:
	if visit.comment:
		return visit.comment

	if visit.punctuality == "noShow":
		return "Клиент не пришёл на запись."

	parts: list[str] = []
	if visit.punctuality == "onTime":
		parts.append("Пришёл вовремя")
	elif visit.punctuality == "late":
		parts.append("Опоздал")

	if visit.paid_in_full:
		parts.append("оплатил полностью")
	else:
		parts.append("оплата неполная")

	if visit.had_behavior_issues:
		behavior_parts: list[str] = []
		if visit.was_unfriendly:
			behavior_parts.append("недружелюбное поведение")
		if visit.had_scandal:
			behavior_parts.append("скандал")
		if visit.threatened_complaints:
			behavior_parts.append("угрозы или жалобы")
		if visit.demanded_discount:
			behavior_parts.append("требовал скидку")
		if visit.stole_from_salon:
			behavior_parts.append("попытка кражи")
		if behavior_parts:
			parts.append(", ".join(behavior_parts))
		else:
			parts.append("проблемы с поведением")

	if visit.left_tips:
		parts.append("оставил чаевые")

	return ", ".join(parts) + "."


def recalculate_profile_aggregates(db: Session, profile: models.ClientProfile) -> None:
	no_shows = db.scalar(
		select(func.count())
		.select_from(models.VisitResult)
		.join(models.Appointment, models.Appointment.id == models.VisitResult.appointment_id)
		.where(
			models.Appointment.client_phone_digits == profile.phone_digits,
			models.VisitResult.punctuality == "noShow",
		)
	) or 0

	scandals = db.scalar(
		select(func.count())
		.select_from(models.VisitResult)
		.join(models.Appointment, models.Appointment.id == models.VisitResult.appointment_id)
		.where(
			models.Appointment.client_phone_digits == profile.phone_digits,
			models.VisitResult.had_behavior_issues.is_(True),
		)
	) or 0

	reviews = db.scalars(
		select(models.MasterReview).where(
			models.MasterReview.client_profile_id == profile.id,
		)
	).all()

	if reviews:
		average = round(sum(review.rating for review in reviews) / len(reviews), 1)
	else:
		average = profile.reviews_average

	yclients_fails = int(profile.yclients_fail_visits_count or 0)
	profile.no_shows_count = max(int(no_shows), yclients_fails)
	profile.scandals_count = int(scandals)
	profile.reviews_count = len(reviews)
	profile.reviews_average = average
	profile.rating_label = rating_label_for(average)
	title, subtitle = reliability_texts(average, profile.no_shows_count, profile.scandals_count)
	profile.reliability_title = title
	profile.reliability_subtitle = subtitle
	db.add(profile)


def apply_yclients_fail_visits(
	db: Session,
	phone_digits: str,
	client_name: str,
	fail_visits_count: int,
) -> models.ClientProfile:
	profile = get_or_create_client_profile(db, phone_digits, client_name)
	fail_count = max(0, int(fail_visits_count))
	profile.yclients_fail_visits_count = fail_count

	local_no_shows = db.scalar(
		select(func.count())
		.select_from(models.VisitResult)
		.join(models.Appointment, models.Appointment.id == models.VisitResult.appointment_id)
		.where(
			models.Appointment.client_phone_digits == phone_digits,
			models.VisitResult.punctuality == "noShow",
		)
	) or 0
	profile.no_shows_count = max(int(local_no_shows), fail_count)
	title, subtitle = reliability_texts(
		profile.reviews_average,
		profile.no_shows_count,
		profile.scandals_count,
	)
	profile.reliability_title = title
	profile.reliability_subtitle = subtitle
	db.add(profile)
	return profile


def apply_visit_result_to_client(
	db: Session,
	appointment: models.Appointment,
	visit: models.VisitResult,
	master: models.Master,
) -> models.ClientProfile:
	profile = get_or_create_client_profile(
		db,
		appointment.client_phone_digits,
		appointment.client_name,
	)

	rating = visit_result_rating(
		visit.punctuality,
		visit.paid_in_full,
		visit.had_behavior_issues,
		visit.was_unfriendly,
		visit.had_scandal,
		visit.threatened_complaints,
		visit.demanded_discount,
		visit.stole_from_salon,
		visit.left_tips,
	)
	now = datetime.now(timezone.utc)
	review_text = _visit_review_text(visit)

	existing_review = db.scalar(
		select(models.MasterReview).where(
			models.MasterReview.appointment_id == appointment.id,
		)
	)
	if existing_review:
		existing_review.rating = rating
		existing_review.text = review_text
		existing_review.review_month = now.month
		existing_review.review_year = now.year
		db.add(existing_review)
	else:
		db.add(
			models.MasterReview(
				client_profile_id=profile.id,
				master_id=master.id,
				appointment_id=appointment.id,
				author_name=master.first_name,
				rating=rating,
				text=review_text,
				review_month=now.month,
				review_year=now.year,
			)
		)

	recalculate_profile_aggregates(db, profile)

	appointment.client_rating = profile.reviews_average
	appointment.risk_level = risk_level_from_rating(profile.reviews_average)
	appointment.status = "no_show" if visit.punctuality == "noShow" else "completed"
	appointment.days_since_verified = days_since_last_check(db, appointment.client_phone_digits)
	db.add(appointment)

	return profile


def sync_appointment_client_fields(
	db: Session,
	appointment: models.Appointment,
) -> None:
	appointment.days_since_verified = days_since_last_check(
		db,
		appointment.client_phone_digits,
	)

	profile = db.scalar(
		select(models.ClientProfile).where(
			models.ClientProfile.phone_digits == appointment.client_phone_digits,
		)
	)
	if profile is None:
		return

	appointment.client_rating = profile.reviews_average
	appointment.risk_level = risk_level_from_rating(profile.reviews_average)


def add_client_review(
	db: Session,
	phone_digits: str,
	client_name: str,
	master: models.Master,
	rating: float,
	text: str,
) -> models.ClientProfile:
	clamped_rating = round(max(1.0, min(5.0, rating)), 1)
	profile = get_or_create_client_profile(db, phone_digits, client_name)
	now = datetime.now(timezone.utc)

	db.add(
		models.MasterReview(
			client_profile_id=profile.id,
			master_id=master.id,
			appointment_id=None,
			author_name=master.first_name,
			rating=clamped_rating,
			text=text.strip(),
			review_month=now.month,
			review_year=now.year,
		)
	)
	recalculate_profile_aggregates(db, profile)
	return profile
