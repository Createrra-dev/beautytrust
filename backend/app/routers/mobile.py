from calendar import monthrange
from datetime import datetime, timezone
from io import StringIO
from uuid import uuid4
import csv

from fastapi import APIRouter, Depends, File, HTTPException, Query, UploadFile
from fastapi.responses import StreamingResponse
from sqlalchemy import and_, extract, func, or_, select
from sqlalchemy.orm import Session, joinedload

from app.db import models
from app.db.session import get_db
from app.deps.auth import get_current_master
from app.deps.rate_limit import rate_limit_client_check
from app.schemas.api import (
	AppointmentCreateRequest,
	AppointmentSchema,
	AppointmentUpdateRequest,
	CheckHistoryRecordSchema,
	ClientCheckResponse,
	ClientProfileSchema,
	ClientReviewCreateRequest,
	CommunityMessageCreateRequest,
	CommunityMessageSchema,
	CommunityTopicCreateRequest,
	CommunityTopicSchema,
	DashboardPeriodSchema,
	DashboardStatsSchema,
	DeviceRegisterRequest,
	MasterProfileSchema,
	MasterProfileUpdateRequest,
	MasterReviewSchema,
	MasterSettingsSchema,
	MasterSettingsUpdateRequest,
	MasterServiceCreateRequest,
	MasterServiceSchema,
	MasterServiceUpdateRequest,
	NotificationSchema,
	PhoneCheckRequest,
	ProfileStatsSchema,
	ReceivedMasterReviewSchema,
	SupportMessageCreateRequest,
	SupportTicketCreateRequest,
	SupportTicketSchema,
	VisitResultSchema,
)
from app.services.client_rating_service import (
	add_client_review,
	apply_visit_result_to_client,
	days_since_last_check,
	normalize_phone_digits,
	risk_level_from_rating,
	sync_appointment_client_fields,
)
from app.services.cache_service import cache_delete_prefix, cache_get_json, cache_set_json
from app.services.master_settings_service import load_master_settings, merge_master_settings
from app.services.notification_service import notify_support_reply
from app.services.password_service import normalize_email
from app.services.uploads import avatar_url_for, uploads_root

_RU_MONTHS = (
	"",
	"Январь",
	"Февраль",
	"Март",
	"Апрель",
	"Май",
	"Июнь",
	"Июль",
	"Август",
	"Сентябрь",
	"Октябрь",
	"Ноябрь",
	"Декабрь",
)

_RU_MONTHS_PREPOSITIONAL = (
	"",
	"январю",
	"февралю",
	"марту",
	"апрелю",
	"маю",
	"июню",
	"июлю",
	"августу",
	"сентябрю",
	"октябрю",
	"ноябрю",
	"декабрю",
)

_DEFAULT_SPARKLINE = [0.4, 0.45, 0.5, 0.48, 0.58, 0.62, 0.7, 0.68, 0.8, 0.86, 0.92, 1.0]

router = APIRouter(prefix="/api", tags=["mobile"])


def _format_phone(digits: str) -> str:
	return f"+7 ({digits[0:3]}) {digits[3:6]}-{digits[6:8]}-{digits[8:10]}"


def _initials(name: str) -> str:
	parts = [part for part in name.strip().split() if part]
	if not parts:
		return "?"
	if len(parts) == 1:
		return parts[0][0].upper()
	return f"{parts[0][0]}{parts[1][0]}".upper()


def _profile_schema(profile: models.ClientProfile) -> ClientProfileSchema:
	return ClientProfileSchema(
		phone=_format_phone(profile.phone_digits),
		rating_label=profile.rating_label,
		reviews_average=profile.reviews_average,
		reviews_count=profile.reviews_count,
		no_shows_count=profile.no_shows_count,
		scandals_count=profile.scandals_count,
		reviews=[
			MasterReviewSchema(
				author_name=review.author_name,
				rating=review.rating,
				text=review.text,
				review_month=review.review_month,
				review_year=review.review_year,
			)
			for review in profile.reviews
		],
		reliability_title=profile.reliability_title,
		reliability_subtitle=profile.reliability_subtitle,
	)


def _appointment_schema(appointment: models.Appointment) -> AppointmentSchema:
	visit_result = None
	if appointment.visit_result:
		visit_result = VisitResultSchema(
			punctuality=appointment.visit_result.punctuality,
			paid_in_full=appointment.visit_result.paid_in_full,
			had_scandal=appointment.visit_result.had_scandal,
			left_tips=appointment.visit_result.left_tips,
			comment=appointment.visit_result.comment,
		)

	return AppointmentSchema(
		id=appointment.external_id,
		client_name=appointment.client_name,
		client_phone_digits=appointment.client_phone_digits,
		service_name=appointment.service_name,
		service_duration_label=appointment.service_duration_label,
		scheduled_at=appointment.scheduled_at,
		service_price=appointment.service_price,
		client_rating=appointment.client_rating,
		risk_level=appointment.risk_level,
		status=appointment.status,
		days_since_verified=appointment.days_since_verified,
		visit_result=visit_result,
	)


def _get_master_appointment(
	db: Session,
	master_id: int,
	appointment_id: str,
) -> models.Appointment:
	appointment = db.scalar(
		select(models.Appointment)
		.options(joinedload(models.Appointment.visit_result))
		.where(
			models.Appointment.external_id == appointment_id,
			models.Appointment.master_id == master_id,
		)
	)
	if appointment is None:
		raise HTTPException(status_code=404, detail="Appointment not found")
	return appointment


def _get_master_support_ticket(
	db: Session,
	master_id: int,
	ticket_id: str,
) -> models.SupportTicket:
	ticket = db.scalar(
		select(models.SupportTicket).where(
			models.SupportTicket.external_id == ticket_id,
			models.SupportTicket.master_id == master_id,
		)
	)
	if ticket is None:
		raise HTTPException(status_code=404, detail="Ticket not found")
	return ticket


def _period_label(year: int, month: int) -> str:
	return f"{_RU_MONTHS[month]} {year}"


def _month_bounds(year: int, month: int) -> tuple[datetime, datetime]:
	start = datetime(year, month, 1, tzinfo=timezone.utc)
	last_day = monthrange(year, month)[1]
	end = datetime(year, month, last_day, 23, 59, 59, 999999, tzinfo=timezone.utc)
	return start, end


def _previous_month(year: int, month: int) -> tuple[int, int]:
	if month == 1:
		return year - 1, 12
	return year, month - 1


def _invalidate_dashboard_cache(master_id: int) -> None:
	cache_delete_prefix(f"dashboard:stats:{master_id}:")


def _risk_level_from_rating(rating: float) -> str:
	return risk_level_from_rating(rating)


_APPOINTMENT_STATUSES = {"scheduled", "completed", "no_show", "cancelled"}


def _percent_trend_label(current: int, previous: int, compare_month: int) -> str:
	month_gen = _RU_MONTHS_PREPOSITIONAL[compare_month]
	if previous == 0:
		if current == 0:
			return f"0 к {month_gen}"
		return f"+100% к {month_gen}"
	delta_pct = round(((current - previous) / previous) * 100)
	sign = "+" if delta_pct > 0 else ""
	return f"{sign}{delta_pct}% к {month_gen}"


def _count_trend_label(current: int, previous: int, compare_month: int) -> str:
	month_gen = _RU_MONTHS_PREPOSITIONAL[compare_month]
	delta = current - previous
	sign = "+" if delta > 0 else ""
	return f"{sign}{delta} к {month_gen}"


def _dashboard_metrics(db: Session, master_id: int, year: int, month: int) -> tuple[int, int, int]:
	start, end = _month_bounds(year, month)
	appointments = db.scalars(
		select(models.Appointment)
		.options(joinedload(models.Appointment.visit_result))
		.where(
			models.Appointment.master_id == master_id,
			models.Appointment.scheduled_at >= start,
			models.Appointment.scheduled_at <= end,
		)
	).unique().all()

	protected_income = 0
	prevented_no_shows = 0
	for appointment in appointments:
		if appointment.status != "completed":
			continue
		protected_income += appointment.service_price
		if appointment.risk_level == "high":
			prevented_no_shows += 1

	completed_checks = db.scalar(
		select(func.count())
		.select_from(models.CheckHistoryRecord)
		.where(
			models.CheckHistoryRecord.master_id == master_id,
			models.CheckHistoryRecord.checked_at >= start,
			models.CheckHistoryRecord.checked_at <= end,
		)
	) or 0

	return protected_income, prevented_no_shows, int(completed_checks)


def _sparkline_values(db: Session, master_id: int, year: int, month: int) -> list[float]:
	start, end = _month_bounds(year, month)
	rows = db.execute(
		select(
			extract("day", models.Appointment.scheduled_at).label("day"),
			func.coalesce(func.sum(models.Appointment.service_price), 0).label("income"),
		)
		.where(
			models.Appointment.master_id == master_id,
			models.Appointment.scheduled_at >= start,
			models.Appointment.scheduled_at <= end,
			models.Appointment.status == "completed",
		)
		.group_by("day")
	).all()

	if not rows:
		return list(_DEFAULT_SPARKLINE)

	days_in_month = monthrange(year, month)[1]
	daily = [0.0] * days_in_month
	for day, income in rows:
		daily[int(day) - 1] = float(income)

	# Compress into 12 buckets for the chart.
	bucket_count = 12
	buckets = [0.0] * bucket_count
	for index, value in enumerate(daily):
		bucket_index = min(bucket_count - 1, (index * bucket_count) // days_in_month)
		buckets[bucket_index] += value

	peak = max(buckets)
	if peak <= 0:
		return list(_DEFAULT_SPARKLINE)
	return [round(value / peak, 4) for value in buckets]


def _get_master_service(
	db: Session,
	master_id: int,
	service_id: int,
) -> models.MasterService:
	service = db.scalar(
		select(models.MasterService).where(
			models.MasterService.id == service_id,
			or_(
				models.MasterService.master_id == master_id,
				models.MasterService.master_id.is_(None),
			),
		)
	)
	if service is None:
		raise HTTPException(status_code=404, detail="Service not found")
	return service


@router.get("/health")
async def api_health() -> dict[str, str]:
	return {"status": "ok", "service": "beautytrust-api"}


def _years_experience(master: models.Master) -> int:
	created = master.created_at
	if created is None:
		return 0
	if created.tzinfo is None:
		created = created.replace(tzinfo=timezone.utc)
	days = max(0, (datetime.now(timezone.utc) - created).days)
	return days // 365


def _refresh_master_stats(db: Session, master: models.Master) -> None:
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
	db.commit()
	db.refresh(master)


def _master_profile_schema(master: models.Master) -> MasterProfileSchema:
	return MasterProfileSchema(
		first_name=master.first_name,
		badge_label=master.badge_label,
		rating=master.rating,
		reviews_count=master.reviews_count,
		clients_count=master.clients_count,
		prevented_no_shows=master.prevented_no_shows,
		protected_income=master.protected_income,
		tariff_label=master.tariff_label,
		avatar_url=avatar_url_for(master),
		email=master.email,
		phone_digits=master.phone_digits,
		years_experience=_years_experience(master),
		onboarding_completed=master.onboarding_completed,
	)


def _delete_avatar_file(relative_path: str | None) -> None:
	if not relative_path:
		return
	file_path = uploads_root() / relative_path
	if file_path.is_file():
		file_path.unlink()


@router.get("/profile", response_model=MasterProfileSchema)
async def get_profile(
	db: Session = Depends(get_db),
	master: models.Master = Depends(get_current_master),
) -> MasterProfileSchema:
	_refresh_master_stats(db, master)
	return _master_profile_schema(master)


@router.patch("/profile", response_model=MasterProfileSchema)
async def update_profile(
	body: MasterProfileUpdateRequest,
	db: Session = Depends(get_db),
	master: models.Master = Depends(get_current_master),
) -> MasterProfileSchema:
	if body.first_name is not None:
		first_name = body.first_name.strip()
		if len(first_name) < 2:
			raise HTTPException(status_code=400, detail="Имя слишком короткое")
		if len(first_name) > 120:
			raise HTTPException(status_code=400, detail="Имя слишком длинное")
		master.first_name = first_name

	if body.badge_label is not None:
		badge_label = body.badge_label.strip()
		if not badge_label:
			raise HTTPException(status_code=400, detail="Значок не может быть пустым")
		if len(badge_label) > 120:
			raise HTTPException(status_code=400, detail="Значок слишком длинный")
		master.badge_label = badge_label

	if body.email is not None:
		try:
			normalized = normalize_email(body.email)
		except ValueError as error:
			raise HTTPException(status_code=400, detail=str(error)) from error

		if normalized is not None:
			existing = db.scalar(
				select(models.Master).where(
					models.Master.email == normalized,
					models.Master.id != master.id,
				)
			)
			if existing is not None:
				raise HTTPException(status_code=400, detail="Email уже занят")
		master.email = normalized

	db.add(master)
	db.commit()
	db.refresh(master)
	_refresh_master_stats(db, master)
	return _master_profile_schema(master)


@router.post("/profile/avatar", response_model=MasterProfileSchema)
async def upload_profile_avatar(
	file: UploadFile = File(...),
	db: Session = Depends(get_db),
	master: models.Master = Depends(get_current_master),
) -> MasterProfileSchema:
	content_type = (file.content_type or "").lower()
	allowed = {
		"image/jpeg": ".jpg",
		"image/jpg": ".jpg",
		"image/png": ".png",
		"image/webp": ".webp",
	}
	extension = allowed.get(content_type)
	if extension is None:
		filename = (file.filename or "").lower()
		if filename.endswith(".png"):
			extension = ".png"
		elif filename.endswith(".webp"):
			extension = ".webp"
		elif filename.endswith(".jpg") or filename.endswith(".jpeg"):
			extension = ".jpg"
		else:
			raise HTTPException(status_code=400, detail="Допустимы только JPEG, PNG или WebP")

	payload = await file.read()
	if not payload:
		raise HTTPException(status_code=400, detail="Пустой файл")
	if len(payload) > 5 * 1024 * 1024:
		raise HTTPException(status_code=400, detail="Файл больше 5 МБ")

	avatars_dir = uploads_root() / "avatars"
	avatars_dir.mkdir(parents=True, exist_ok=True)
	relative_path = f"avatars/master_{master.id}_{uuid4().hex}{extension}"
	target = uploads_root() / relative_path
	target.write_bytes(payload)

	previous = master.avatar_path
	master.avatar_path = relative_path
	db.add(master)
	db.commit()
	db.refresh(master)

	if previous and previous != relative_path:
		_delete_avatar_file(previous)

	return _master_profile_schema(master)


@router.delete("/profile/avatar", response_model=MasterProfileSchema)
async def delete_profile_avatar(
	db: Session = Depends(get_db),
	master: models.Master = Depends(get_current_master),
) -> MasterProfileSchema:
	previous = master.avatar_path
	master.avatar_path = None
	db.add(master)
	db.commit()
	db.refresh(master)
	_delete_avatar_file(previous)
	return _master_profile_schema(master)


@router.post("/profile/onboarding/complete", response_model=MasterProfileSchema)
async def complete_onboarding(
	db: Session = Depends(get_db),
	master: models.Master = Depends(get_current_master),
) -> MasterProfileSchema:
	master.onboarding_completed = True
	db.add(master)
	db.commit()
	db.refresh(master)
	return _master_profile_schema(master)


@router.get("/profile/stats", response_model=ProfileStatsSchema)
async def get_profile_stats(
	db: Session = Depends(get_db),
	master: models.Master = Depends(get_current_master),
) -> ProfileStatsSchema:
	status_rows = db.execute(
		select(models.Appointment.status, func.count())
		.where(models.Appointment.master_id == master.id)
		.group_by(models.Appointment.status)
	).all()
	status_counts = {status: int(count) for status, count in status_rows}

	scheduled = status_counts.get("scheduled", 0)
	completed = status_counts.get("completed", 0)
	no_show = status_counts.get("no_show", 0)
	cancelled = status_counts.get("cancelled", 0)
	total = scheduled + completed + no_show + cancelled
	finished = completed + no_show
	completion_rate = round((completed / finished) * 100, 1) if finished > 0 else 0.0

	avg_rating = db.scalar(
		select(func.avg(models.Appointment.client_rating)).where(
			models.Appointment.master_id == master.id,
		)
	)
	checks_total = db.scalar(
		select(func.count())
		.select_from(models.CheckHistoryRecord)
		.where(models.CheckHistoryRecord.master_id == master.id)
	) or 0
	reviews_given = db.scalar(
		select(func.count())
		.select_from(models.MasterReview)
		.where(models.MasterReview.master_id == master.id)
	) or 0

	return ProfileStatsSchema(
		appointments_total=total,
		appointments_scheduled=scheduled,
		appointments_completed=completed,
		appointments_no_show=no_show,
		appointments_cancelled=cancelled,
		completion_rate=completion_rate,
		avg_client_rating=round(float(avg_rating or 0), 1),
		checks_total=int(checks_total),
		reviews_given=int(reviews_given),
	)


@router.get("/profile/reviews", response_model=list[ReceivedMasterReviewSchema])
async def list_profile_reviews(
	limit: int = Query(default=50, ge=1, le=200),
	offset: int = Query(default=0, ge=0),
	db: Session = Depends(get_db),
	master: models.Master = Depends(get_current_master),
) -> list[ReceivedMasterReviewSchema]:
	reviews = db.scalars(
		select(models.MasterReceivedReview)
		.where(models.MasterReceivedReview.master_id == master.id)
		.order_by(
			models.MasterReceivedReview.review_year.desc(),
			models.MasterReceivedReview.review_month.desc(),
			models.MasterReceivedReview.id.desc(),
		)
		.offset(offset)
		.limit(limit)
	).all()
	return [
		ReceivedMasterReviewSchema(
			id=review.id,
			author_name=review.author_name,
			rating=review.rating,
			text=review.text,
			review_month=review.review_month,
			review_year=review.review_year,
		)
		for review in reviews
	]


@router.get("/profile/settings", response_model=MasterSettingsSchema)
async def get_profile_settings(
	master: models.Master = Depends(get_current_master),
) -> MasterSettingsSchema:
	return MasterSettingsSchema(**load_master_settings(master))


@router.patch("/profile/settings", response_model=MasterSettingsSchema)
async def update_profile_settings(
	body: MasterSettingsUpdateRequest,
	db: Session = Depends(get_db),
	master: models.Master = Depends(get_current_master),
) -> MasterSettingsSchema:
	updates = body.model_dump(exclude_unset=True)
	settings = merge_master_settings(master, updates)
	db.add(master)
	db.commit()
	db.refresh(master)
	return MasterSettingsSchema(**settings)


@router.get("/dashboard/stats", response_model=DashboardStatsSchema)
async def get_dashboard_stats(
	year: int = Query(default=2026),
	month: int = Query(default=7, ge=1, le=12),
	db: Session = Depends(get_db),
	master: models.Master = Depends(get_current_master),
) -> DashboardStatsSchema:
	if year < 2000 or year > 2100:
		raise HTTPException(status_code=400, detail="Invalid year")

	cache_key = f"dashboard:stats:{master.id}:{year}:{month}"
	cached = cache_get_json(cache_key)
	if cached is not None:
		return DashboardStatsSchema(**cached)

	protected_income, prevented_no_shows, completed_checks = _dashboard_metrics(
		db, master.id, year, month
	)
	prev_year, prev_month = _previous_month(year, month)
	prev_income, prev_no_shows, prev_checks = _dashboard_metrics(
		db, master.id, prev_year, prev_month
	)

	result = DashboardStatsSchema(
		period_label=_period_label(year, month),
		protected_income=protected_income,
		income_trend_label=_percent_trend_label(protected_income, prev_income, prev_month),
		income_trend_positive=protected_income >= prev_income,
		sparkline_values=_sparkline_values(db, master.id, year, month),
		prevented_no_shows=prevented_no_shows,
		no_shows_trend_label=_count_trend_label(prevented_no_shows, prev_no_shows, prev_month),
		completed_checks=completed_checks,
		checks_trend_label=_count_trend_label(completed_checks, prev_checks, prev_month),
	)
	cache_set_json(cache_key, result.model_dump(), 60)
	return result


@router.get("/dashboard/periods", response_model=list[DashboardPeriodSchema])
async def get_dashboard_periods(
	db: Session = Depends(get_db),
	master: models.Master = Depends(get_current_master),
) -> list[DashboardPeriodSchema]:
	period_keys: set[tuple[int, int]] = set()

	appointment_periods = db.execute(
		select(
			extract("year", models.Appointment.scheduled_at),
			extract("month", models.Appointment.scheduled_at),
		)
		.where(models.Appointment.master_id == master.id)
		.distinct()
	).all()
	for year_value, month_value in appointment_periods:
		period_keys.add((int(year_value), int(month_value)))

	check_periods = db.execute(
		select(
			extract("year", models.CheckHistoryRecord.checked_at),
			extract("month", models.CheckHistoryRecord.checked_at),
		)
		.where(models.CheckHistoryRecord.master_id == master.id)
		.distinct()
	).all()
	for year_value, month_value in check_periods:
		period_keys.add((int(year_value), int(month_value)))

	now = datetime.now(timezone.utc)
	cursor = datetime(now.year, now.month, 1, tzinfo=timezone.utc)
	for _ in range(6):
		period_keys.add((cursor.year, cursor.month))
		prev_year, prev_month = _previous_month(cursor.year, cursor.month)
		cursor = datetime(prev_year, prev_month, 1, tzinfo=timezone.utc)

	sorted_periods = sorted(period_keys, key=lambda item: (item[0], item[1]), reverse=True)
	return [
		DashboardPeriodSchema(year=year, month=month, label=_period_label(year, month))
		for year, month in sorted_periods
	]


@router.get("/master/services", response_model=list[MasterServiceSchema])
async def list_services(
	db: Session = Depends(get_db),
	master: models.Master = Depends(get_current_master),
) -> list[MasterServiceSchema]:
	services = db.scalars(
		select(models.MasterService)
		.where(
			or_(
				models.MasterService.master_id == master.id,
				models.MasterService.master_id.is_(None),
			)
		)
		.order_by(models.MasterService.id)
	).all()
	return [
		MasterServiceSchema(
			id=service.id,
			name=service.name,
			duration_label=service.duration_label,
			price=service.price,
			is_owned=service.master_id == master.id,
		)
		for service in services
	]


@router.post("/master/services", response_model=MasterServiceSchema)
async def create_service(
	body: MasterServiceCreateRequest,
	db: Session = Depends(get_db),
	master: models.Master = Depends(get_current_master),
) -> MasterServiceSchema:
	name = body.name.strip()
	duration_label = body.duration_label.strip()
	if len(name) < 2:
		raise HTTPException(status_code=400, detail="Название слишком короткое")
	if not duration_label:
		raise HTTPException(status_code=400, detail="Укажите длительность")
	if body.price < 0:
		raise HTTPException(status_code=400, detail="Цена не может быть отрицательной")

	service = models.MasterService(
		master_id=master.id,
		name=name,
		duration_label=duration_label,
		price=body.price,
	)
	db.add(service)
	db.commit()
	db.refresh(service)
	return MasterServiceSchema(
		id=service.id,
		name=service.name,
		duration_label=service.duration_label,
		price=service.price,
		is_owned=True,
	)


@router.patch("/master/services/{service_id}", response_model=MasterServiceSchema)
async def update_service(
	service_id: int,
	body: MasterServiceUpdateRequest,
	db: Session = Depends(get_db),
	master: models.Master = Depends(get_current_master),
) -> MasterServiceSchema:
	service = _get_master_service(db, master.id, service_id)
	payload = body.model_dump(exclude_unset=True)
	if "name" in payload and payload["name"] is not None:
		name = payload["name"].strip()
		if len(name) < 2:
			raise HTTPException(status_code=400, detail="Название слишком короткое")
		payload["name"] = name
	if "duration_label" in payload and payload["duration_label"] is not None:
		duration_label = payload["duration_label"].strip()
		if not duration_label:
			raise HTTPException(status_code=400, detail="Укажите длительность")
		payload["duration_label"] = duration_label
	if "price" in payload and payload["price"] is not None and payload["price"] < 0:
		raise HTTPException(status_code=400, detail="Цена не может быть отрицательной")

	for field, value in payload.items():
		setattr(service, field, value)
	# Claim legacy global services when edited by a master.
	if service.master_id is None:
		service.master_id = master.id
	db.commit()
	db.refresh(service)
	return MasterServiceSchema(
		id=service.id,
		name=service.name,
		duration_label=service.duration_label,
		price=service.price,
		is_owned=service.master_id == master.id,
	)


@router.delete("/master/services/{service_id}")
async def delete_service(
	service_id: int,
	db: Session = Depends(get_db),
	master: models.Master = Depends(get_current_master),
) -> dict[str, bool]:
	service = db.scalar(
		select(models.MasterService).where(
			models.MasterService.id == service_id,
			models.MasterService.master_id == master.id,
		)
	)
	if service is None:
		raise HTTPException(status_code=404, detail="Service not found")
	db.delete(service)
	db.commit()
	return {"ok": True}


@router.get("/appointments", response_model=list[AppointmentSchema])
async def list_appointments(
	from_: datetime | None = Query(default=None, alias="from"),
	to: datetime | None = Query(default=None),
	limit: int = Query(default=100, ge=1, le=200),
	offset: int = Query(default=0, ge=0),
	db: Session = Depends(get_db),
	master: models.Master = Depends(get_current_master),
) -> list[AppointmentSchema]:
	filters = [models.Appointment.master_id == master.id]
	if from_ is not None:
		filters.append(models.Appointment.scheduled_at >= from_)
	if to is not None:
		filters.append(models.Appointment.scheduled_at <= to)

	appointments = db.scalars(
		select(models.Appointment)
		.options(joinedload(models.Appointment.visit_result))
		.where(and_(*filters))
		.order_by(models.Appointment.scheduled_at)
		.offset(offset)
		.limit(limit)
	).unique().all()
	return [_appointment_schema(item) for item in appointments]


@router.get("/appointments/{appointment_id}", response_model=AppointmentSchema)
async def get_appointment(
	appointment_id: str,
	db: Session = Depends(get_db),
	master: models.Master = Depends(get_current_master),
) -> AppointmentSchema:
	appointment = _get_master_appointment(db, master.id, appointment_id)
	return _appointment_schema(appointment)


@router.post("/appointments", response_model=AppointmentSchema)
async def create_appointment(
	body: AppointmentCreateRequest,
	db: Session = Depends(get_db),
	master: models.Master = Depends(get_current_master),
) -> AppointmentSchema:
	try:
		phone_digits = normalize_phone_digits(body.client_phone_digits)
	except ValueError as error:
		raise HTTPException(status_code=400, detail=str(error)) from error

	external_id = f"appointment-{int(datetime.now(timezone.utc).timestamp())}"
	appointment = models.Appointment(
		external_id=external_id,
		master_id=master.id,
		client_name=body.client_name,
		client_phone_digits=phone_digits,
		service_name=body.service_name,
		service_duration_label=body.service_duration_label,
		scheduled_at=body.scheduled_at,
		service_price=body.service_price,
		client_rating=body.client_rating,
		risk_level=body.risk_level,
		status="scheduled",
		days_since_verified=body.days_since_verified,
	)
	sync_appointment_client_fields(db, appointment)
	db.add(appointment)
	db.commit()
	db.refresh(appointment)
	_invalidate_dashboard_cache(master.id)
	return _appointment_schema(appointment)


@router.patch("/appointments/{appointment_id}", response_model=AppointmentSchema)
async def update_appointment(
	appointment_id: str,
	body: AppointmentUpdateRequest,
	db: Session = Depends(get_db),
	master: models.Master = Depends(get_current_master),
) -> AppointmentSchema:
	appointment = _get_master_appointment(db, master.id, appointment_id)
	phone_changed = False

	for field, value in body.model_dump(exclude_unset=True).items():
		if field == "status":
			if value not in _APPOINTMENT_STATUSES:
				raise HTTPException(status_code=400, detail="Invalid appointment status")
			if appointment.visit_result is not None and value in {"scheduled", "cancelled"}:
				raise HTTPException(
					status_code=400,
					detail="Cannot change status after visit result is saved",
				)
		if field == "client_phone_digits" and value != appointment.client_phone_digits:
			phone_changed = True
		setattr(appointment, field, value)

	if phone_changed or body.client_phone_digits is not None:
		sync_appointment_client_fields(db, appointment)

	db.commit()
	db.refresh(appointment)
	_invalidate_dashboard_cache(master.id)
	return _appointment_schema(appointment)


@router.delete("/appointments/{appointment_id}")
async def delete_appointment(
	appointment_id: str,
	db: Session = Depends(get_db),
	master: models.Master = Depends(get_current_master),
) -> dict[str, bool]:
	appointment = _get_master_appointment(db, master.id, appointment_id)
	if appointment.visit_result is not None:
		db.delete(appointment.visit_result)
	db.delete(appointment)
	db.commit()
	_invalidate_dashboard_cache(master.id)
	return {"ok": True}


@router.post("/appointments/{appointment_id}/visit-result", response_model=AppointmentSchema)
async def save_visit_result(
	appointment_id: str,
	body: VisitResultSchema,
	db: Session = Depends(get_db),
	master: models.Master = Depends(get_current_master),
) -> AppointmentSchema:
	appointment = _get_master_appointment(db, master.id, appointment_id)

	if appointment.visit_result:
		visit_result = appointment.visit_result
		visit_result.punctuality = body.punctuality
		visit_result.paid_in_full = body.paid_in_full
		visit_result.had_scandal = body.had_scandal
		visit_result.left_tips = body.left_tips
		visit_result.comment = body.comment
	else:
		visit_result = models.VisitResult(
			punctuality=body.punctuality,
			paid_in_full=body.paid_in_full,
			had_scandal=body.had_scandal,
			left_tips=body.left_tips,
			comment=body.comment,
		)
		appointment.visit_result = visit_result

	db.flush()
	apply_visit_result_to_client(db, appointment, visit_result, master)
	_refresh_master_stats(db, master)
	db.commit()
	db.refresh(appointment)
	_invalidate_dashboard_cache(master.id)
	return _appointment_schema(appointment)


@router.post(
	"/clients/check",
	response_model=ClientCheckResponse,
	dependencies=[Depends(rate_limit_client_check)],
)
async def check_client(
	body: PhoneCheckRequest,
	db: Session = Depends(get_db),
	master: models.Master = Depends(get_current_master),
) -> ClientCheckResponse:
	digits = "".join(char for char in body.phone if char.isdigit())
	if len(digits) == 11 and digits.startswith("7"):
		digits = digits[1:]
	if len(digits) != 10:
		raise HTTPException(status_code=400, detail="Invalid phone number")

	profile = db.scalar(
		select(models.ClientProfile)
		.options(joinedload(models.ClientProfile.reviews))
		.where(models.ClientProfile.phone_digits == digits)
	)
	if profile is None:
		raise HTTPException(status_code=404, detail="Client not found")

	now = datetime.now(timezone.utc)
	days_since = days_since_last_check(db, digits)
	db.add(
		models.CheckHistoryRecord(
			external_id=f"check-{int(now.timestamp() * 1000)}",
			master_id=master.id,
			client_name=profile.client_name,
			phone_digits=profile.phone_digits,
			rating=profile.reviews_average,
			risk_level=_risk_level_from_rating(profile.reviews_average),
			checked_at=now,
		)
	)

	for appointment in db.scalars(
		select(models.Appointment).where(
			models.Appointment.master_id == master.id,
			models.Appointment.client_phone_digits == digits,
			models.Appointment.status == "scheduled",
		)
	).all():
		appointment.days_since_verified = days_since
		appointment.client_rating = profile.reviews_average
		appointment.risk_level = _risk_level_from_rating(profile.reviews_average)
		db.add(appointment)

	db.commit()

	return ClientCheckResponse(
		client_name=profile.client_name,
		profile=_profile_schema(profile),
	)


@router.post("/clients/{phone}/reviews", response_model=ClientProfileSchema)
async def create_client_review(
	phone: str,
	body: ClientReviewCreateRequest,
	db: Session = Depends(get_db),
	master: models.Master = Depends(get_current_master),
) -> ClientProfileSchema:
	try:
		digits = normalize_phone_digits(phone)
	except ValueError as error:
		raise HTTPException(status_code=400, detail=str(error)) from error

	profile = db.scalar(
		select(models.ClientProfile).where(models.ClientProfile.phone_digits == digits)
	)
	client_name = body.client_name or (profile.client_name if profile else "Клиент")

	profile = add_client_review(
		db,
		digits,
		client_name,
		master,
		body.rating,
		body.text,
	)
	db.commit()
	db.refresh(profile)

	for appointment in db.scalars(
		select(models.Appointment).where(
			models.Appointment.master_id == master.id,
			models.Appointment.client_phone_digits == digits,
		)
	).all():
		appointment.client_rating = profile.reviews_average
		appointment.risk_level = _risk_level_from_rating(profile.reviews_average)
		db.add(appointment)
	db.commit()

	profile = db.scalar(
		select(models.ClientProfile)
		.options(joinedload(models.ClientProfile.reviews))
		.where(models.ClientProfile.id == profile.id)
	)
	if profile is None:
		raise HTTPException(status_code=404, detail="Client not found")
	return _profile_schema(profile)


@router.get("/reports/appointments")
async def export_appointments_report(
	format: str = Query(default="csv"),
	from_: datetime | None = Query(default=None, alias="from"),
	to: datetime | None = Query(default=None),
	db: Session = Depends(get_db),
	master: models.Master = Depends(get_current_master),
):
	if format != "csv":
		raise HTTPException(status_code=400, detail="Only csv format is supported")

	filters = [models.Appointment.master_id == master.id]
	if from_ is not None:
		filters.append(models.Appointment.scheduled_at >= from_)
	if to is not None:
		filters.append(models.Appointment.scheduled_at <= to)

	appointments = db.scalars(
		select(models.Appointment)
		.options(joinedload(models.Appointment.visit_result))
		.where(and_(*filters))
		.order_by(models.Appointment.scheduled_at)
	).unique().all()

	buffer = StringIO()
	writer = csv.writer(buffer)
	writer.writerow(
		[
			"id",
			"client_name",
			"client_phone",
			"service_name",
			"scheduled_at",
			"service_price",
			"status",
			"client_rating",
			"risk_level",
			"days_since_verified",
			"visit_punctuality",
			"visit_paid_in_full",
			"visit_had_scandal",
			"visit_left_tips",
		]
	)
	for item in appointments:
		visit = item.visit_result
		writer.writerow(
			[
				item.external_id,
				item.client_name,
				item.client_phone_digits,
				item.service_name,
				item.scheduled_at.isoformat(),
				item.service_price,
				item.status,
				item.client_rating,
				item.risk_level,
				item.days_since_verified,
				visit.punctuality if visit else "",
				visit.paid_in_full if visit else "",
				visit.had_scandal if visit else "",
				visit.left_tips if visit else "",
			]
		)

	buffer.seek(0)
	filename = f"appointments-{master.id}-{datetime.now(timezone.utc).strftime('%Y%m%d')}.csv"
	return StreamingResponse(
		iter([buffer.getvalue()]),
		media_type="text/csv; charset=utf-8",
		headers={"Content-Disposition": f'attachment; filename="{filename}"'},
	)


@router.get("/checks/history", response_model=list[CheckHistoryRecordSchema])
async def list_check_history(
	filter: str = Query(default="all"),
	db: Session = Depends(get_db),
	master: models.Master = Depends(get_current_master),
) -> list[CheckHistoryRecordSchema]:
	if filter not in {"all", "reliable", "risky"}:
		raise HTTPException(status_code=400, detail="Invalid filter")

	filters = [models.CheckHistoryRecord.master_id == master.id]
	if filter == "reliable":
		filters.append(models.CheckHistoryRecord.rating >= 4)
	elif filter == "risky":
		filters.append(models.CheckHistoryRecord.rating < 3.5)

	records = db.scalars(
		select(models.CheckHistoryRecord)
		.where(and_(*filters))
		.order_by(models.CheckHistoryRecord.checked_at.desc())
	).all()
	return [
		CheckHistoryRecordSchema(
			id=record.external_id,
			client_name=record.client_name,
			phone_digits=record.phone_digits,
			rating=record.rating,
			risk_level=record.risk_level,
			checked_at=record.checked_at,
		)
		for record in records
	]


@router.get("/community/topics", response_model=list[CommunityTopicSchema])
async def list_topics(
	q: str = "",
	limit: int = Query(default=50, ge=1, le=200),
	offset: int = Query(default=0, ge=0),
	db: Session = Depends(get_db),
	master: models.Master = Depends(get_current_master),
) -> list[CommunityTopicSchema]:
	query = select(models.CommunityTopic).order_by(
		models.CommunityTopic.is_pinned.desc(),
		models.CommunityTopic.last_message_at.desc(),
	)
	topics = db.scalars(query.offset(offset).limit(limit)).all()
	result = []
	for topic in topics:
		if q and q.lower() not in topic.title.lower() and q.lower() not in topic.last_message.lower():
			continue
		unread = _topic_unread_for_master(db, master.id, topic)
		result.append(
			CommunityTopicSchema(
				id=topic.external_id,
				title=topic.title,
				author_name=topic.author_name,
				created_at=topic.created_at,
				participant_count=topic.participant_count,
				last_message=topic.last_message,
				last_message_at=topic.last_message_at,
				participant_initials=[item.strip() for item in topic.participant_initials.split(",") if item.strip()],
				unread_count=unread,
				is_pinned=topic.is_pinned,
				is_closed=topic.is_closed,
				emoji=topic.emoji,
			)
		)
	return result


def _topic_unread_for_master(db: Session, master_id: int, topic: models.CommunityTopic) -> int:
	read = db.scalar(
		select(models.CommunityTopicRead).where(
			models.CommunityTopicRead.master_id == master_id,
			models.CommunityTopicRead.topic_id == topic.id,
		)
	)
	if read is None:
		return 1 if topic.unread_count > 0 or topic.last_message else 0
	if topic.last_message_at > read.last_read_at:
		return max(1, topic.unread_count)
	return 0


@router.post("/community/topics", response_model=CommunityTopicSchema)
async def create_topic(
	body: CommunityTopicCreateRequest,
	db: Session = Depends(get_db),
	master: models.Master = Depends(get_current_master),
) -> CommunityTopicSchema:
	now = datetime.now(timezone.utc)
	external_id = f"topic-{int(now.timestamp())}"
	author_name = master.first_name
	author_initial = _initials(author_name)
	topic = models.CommunityTopic(
		external_id=external_id,
		title=body.title.strip(),
		author_name=author_name,
		author_master_id=master.id,
		emoji="✨",
		participant_count=1,
		participant_initials=author_initial,
		last_message=body.story.strip(),
		last_message_at=now,
		is_closed=False,
	)
	db.add(topic)
	db.flush()
	db.add(
		models.CommunityMessage(
			external_id=f"m-{int(now.timestamp())}",
			topic_id=topic.id,
			author_name=author_name,
			author_master_id=master.id,
			text=body.story.strip(),
			sent_at=now,
			is_mine=True,
		)
	)
	db.add(
		models.CommunityTopicRead(
			master_id=master.id,
			topic_id=topic.id,
			last_read_at=now,
		)
	)
	db.commit()
	db.refresh(topic)
	return CommunityTopicSchema(
		id=topic.external_id,
		title=topic.title,
		author_name=topic.author_name,
		created_at=topic.created_at,
		participant_count=topic.participant_count,
		last_message=topic.last_message,
		last_message_at=topic.last_message_at,
		participant_initials=[author_initial],
		unread_count=0,
		is_pinned=False,
		is_closed=False,
		emoji=topic.emoji,
	)


@router.patch("/community/topics/{topic_id}/read", response_model=CommunityTopicSchema)
async def mark_topic_read(
	topic_id: str,
	db: Session = Depends(get_db),
	master: models.Master = Depends(get_current_master),
) -> CommunityTopicSchema:
	topic = db.scalar(select(models.CommunityTopic).where(models.CommunityTopic.external_id == topic_id))
	if topic is None:
		raise HTTPException(status_code=404, detail="Topic not found")

	now = datetime.now(timezone.utc)
	read = db.scalar(
		select(models.CommunityTopicRead).where(
			models.CommunityTopicRead.master_id == master.id,
			models.CommunityTopicRead.topic_id == topic.id,
		)
	)
	if read is None:
		db.add(
			models.CommunityTopicRead(
				master_id=master.id,
				topic_id=topic.id,
				last_read_at=now,
			)
		)
	else:
		read.last_read_at = now
		db.add(read)
	db.commit()
	db.refresh(topic)
	return CommunityTopicSchema(
		id=topic.external_id,
		title=topic.title,
		author_name=topic.author_name,
		created_at=topic.created_at,
		participant_count=topic.participant_count,
		last_message=topic.last_message,
		last_message_at=topic.last_message_at,
		participant_initials=[item.strip() for item in topic.participant_initials.split(",") if item.strip()],
		unread_count=0,
		is_pinned=topic.is_pinned,
		is_closed=topic.is_closed,
		emoji=topic.emoji,
	)


@router.post("/community/topics/{topic_id}/close", response_model=CommunityTopicSchema)
async def close_topic(
	topic_id: str,
	db: Session = Depends(get_db),
	master: models.Master = Depends(get_current_master),
) -> CommunityTopicSchema:
	topic = db.scalar(select(models.CommunityTopic).where(models.CommunityTopic.external_id == topic_id))
	if topic is None:
		raise HTTPException(status_code=404, detail="Topic not found")
	if topic.author_master_id is not None and topic.author_master_id != master.id:
		raise HTTPException(status_code=403, detail="Закрыть тему может только автор")

	topic.is_closed = True
	db.add(topic)
	db.commit()
	db.refresh(topic)
	return CommunityTopicSchema(
		id=topic.external_id,
		title=topic.title,
		author_name=topic.author_name,
		created_at=topic.created_at,
		participant_count=topic.participant_count,
		last_message=topic.last_message,
		last_message_at=topic.last_message_at,
		participant_initials=[item.strip() for item in topic.participant_initials.split(",") if item.strip()],
		unread_count=_topic_unread_for_master(db, master.id, topic),
		is_pinned=topic.is_pinned,
		is_closed=topic.is_closed,
		emoji=topic.emoji,
	)


@router.get("/community/topics/{topic_id}/messages", response_model=list[CommunityMessageSchema])
async def list_topic_messages(
	topic_id: str,
	limit: int = Query(default=100, ge=1, le=200),
	offset: int = Query(default=0, ge=0),
	db: Session = Depends(get_db),
	master: models.Master = Depends(get_current_master),
) -> list[CommunityMessageSchema]:
	topic = db.scalar(select(models.CommunityTopic).where(models.CommunityTopic.external_id == topic_id))
	if topic is None:
		raise HTTPException(status_code=404, detail="Topic not found")

	messages = db.scalars(
		select(models.CommunityMessage)
		.where(models.CommunityMessage.topic_id == topic.id)
		.order_by(models.CommunityMessage.sent_at)
		.offset(offset)
		.limit(limit)
	).all()
	return [
		CommunityMessageSchema(
			id=message.external_id,
			topic_id=topic_id,
			author_name=message.author_name,
			text=message.text,
			sent_at=message.sent_at,
			is_mine=message.author_master_id == master.id
			if message.author_master_id is not None
			else message.author_name == master.first_name,
		)
		for message in messages
	]


@router.post("/community/topics/{topic_id}/messages", response_model=CommunityMessageSchema)
async def send_topic_message(
	topic_id: str,
	body: CommunityMessageCreateRequest,
	db: Session = Depends(get_db),
	master: models.Master = Depends(get_current_master),
) -> CommunityMessageSchema:
	topic = db.scalar(select(models.CommunityTopic).where(models.CommunityTopic.external_id == topic_id))
	if topic is None:
		raise HTTPException(status_code=404, detail="Topic not found")
	if topic.is_closed:
		raise HTTPException(status_code=400, detail="Тема закрыта")

	now = datetime.now(timezone.utc)
	message = models.CommunityMessage(
		external_id=f"m-{int(now.timestamp())}",
		topic_id=topic.id,
		author_name=master.first_name,
		author_master_id=master.id,
		text=body.text.strip(),
		sent_at=now,
		is_mine=True,
	)
	topic.last_message = body.text.strip()
	topic.last_message_at = now
	db.add(message)
	db.commit()
	return CommunityMessageSchema(
		id=message.external_id,
		topic_id=topic_id,
		author_name=message.author_name,
		text=message.text,
		sent_at=message.sent_at,
		is_mine=True,
	)


@router.get("/support/tickets", response_model=list[SupportTicketSchema])
async def list_support_tickets(
	q: str = "",
	limit: int = Query(default=50, ge=1, le=200),
	offset: int = Query(default=0, ge=0),
	db: Session = Depends(get_db),
	master: models.Master = Depends(get_current_master),
) -> list[SupportTicketSchema]:
	tickets = db.scalars(
		select(models.SupportTicket)
		.where(models.SupportTicket.master_id == master.id)
		.order_by(models.SupportTicket.last_message_at.desc())
		.offset(offset)
		.limit(limit)
	).all()
	result = []
	for ticket in tickets:
		if q and q.lower() not in ticket.title.lower() and q.lower() not in ticket.last_message.lower():
			continue
		result.append(
			SupportTicketSchema(
				id=ticket.external_id,
				title=ticket.title,
				author_name=ticket.author_name,
				created_at=ticket.created_at,
				last_message=ticket.last_message,
				last_message_at=ticket.last_message_at,
				status=ticket.status,
				unread_count=ticket.unread_count,
			)
		)
	return result


@router.post("/support/tickets", response_model=SupportTicketSchema)
async def create_support_ticket(
	body: SupportTicketCreateRequest,
	db: Session = Depends(get_db),
	master: models.Master = Depends(get_current_master),
) -> SupportTicketSchema:
	now = datetime.now(timezone.utc)
	external_id = f"support-{int(now.timestamp())}"
	ticket = models.SupportTicket(
		external_id=external_id,
		master_id=master.id,
		title=body.title.strip(),
		author_name=master.first_name,
		status="new",
		last_message=body.description.strip(),
		last_message_at=now,
	)
	db.add(ticket)
	db.flush()
	db.add(
		models.SupportMessage(
			external_id=f"s-{int(now.timestamp())}",
			ticket_id=ticket.id,
			author_name=ticket.author_name,
			text=body.description.strip(),
			sent_at=now,
			is_mine=True,
		)
	)
	db.commit()
	db.refresh(ticket)
	return SupportTicketSchema(
		id=ticket.external_id,
		title=ticket.title,
		author_name=ticket.author_name,
		created_at=ticket.created_at,
		last_message=ticket.last_message,
		last_message_at=ticket.last_message_at,
		status=ticket.status,
		unread_count=ticket.unread_count,
	)


@router.get("/support/tickets/{ticket_id}/messages", response_model=list[CommunityMessageSchema])
async def list_support_messages(
	ticket_id: str,
	limit: int = Query(default=100, ge=1, le=200),
	offset: int = Query(default=0, ge=0),
	db: Session = Depends(get_db),
	master: models.Master = Depends(get_current_master),
) -> list[CommunityMessageSchema]:
	ticket = _get_master_support_ticket(db, master.id, ticket_id)
	if ticket.unread_count:
		ticket.unread_count = 0
		db.add(ticket)
		db.commit()

	messages = db.scalars(
		select(models.SupportMessage)
		.where(models.SupportMessage.ticket_id == ticket.id)
		.order_by(models.SupportMessage.sent_at)
		.offset(offset)
		.limit(limit)
	).all()
	return [
		CommunityMessageSchema(
			id=message.external_id,
			topic_id=ticket_id,
			author_name=message.author_name,
			text=message.text,
			sent_at=message.sent_at,
			is_mine=message.is_mine,
			attachment_url=_attachment_url(message.attachment_path),
			attachment_name=message.attachment_name,
		)
		for message in messages
	]


def _attachment_url(relative_path: str | None) -> str | None:
	if not relative_path:
		return None
	from app.config import settings

	return f"{settings.public_base_url.rstrip('/')}/uploads/{relative_path}"


@router.post("/support/tickets/{ticket_id}/messages", response_model=CommunityMessageSchema)
async def send_support_message(
	ticket_id: str,
	body: SupportMessageCreateRequest,
	db: Session = Depends(get_db),
	master: models.Master = Depends(get_current_master),
) -> CommunityMessageSchema:
	ticket = _get_master_support_ticket(db, master.id, ticket_id)
	if ticket.status in {"closed", "cancelled"}:
		raise HTTPException(status_code=400, detail="Ticket is closed")

	now = datetime.now(timezone.utc)
	message = models.SupportMessage(
		external_id=f"s-{int(now.timestamp())}",
		ticket_id=ticket.id,
		author_name=master.first_name,
		text=body.text.strip(),
		sent_at=now,
		is_mine=True,
	)
	ticket.last_message = body.text.strip()
	ticket.last_message_at = now
	ticket.status = "waiting_for_response"
	db.add(message)
	db.commit()
	return CommunityMessageSchema(
		id=message.external_id,
		topic_id=ticket_id,
		author_name=message.author_name,
		text=message.text,
		sent_at=message.sent_at,
		is_mine=True,
	)


@router.post("/support/tickets/{ticket_id}/attachments", response_model=CommunityMessageSchema)
async def upload_support_attachment(
	ticket_id: str,
	file: UploadFile = File(...),
	db: Session = Depends(get_db),
	master: models.Master = Depends(get_current_master),
) -> CommunityMessageSchema:
	ticket = _get_master_support_ticket(db, master.id, ticket_id)
	if ticket.status in {"closed", "cancelled"}:
		raise HTTPException(status_code=400, detail="Ticket is closed")

	payload = await file.read()
	if not payload:
		raise HTTPException(status_code=400, detail="Пустой файл")
	if len(payload) > 10 * 1024 * 1024:
		raise HTTPException(status_code=400, detail="Файл больше 10 МБ")

	filename = (file.filename or "attachment.bin").replace("/", "_")
	relative_path = f"support/{ticket.external_id}_{uuid4().hex}_{filename}"
	target_dir = uploads_root() / "support"
	target_dir.mkdir(parents=True, exist_ok=True)
	(uploads_root() / relative_path).write_bytes(payload)

	now = datetime.now(timezone.utc)
	message = models.SupportMessage(
		external_id=f"s-file-{int(now.timestamp())}",
		ticket_id=ticket.id,
		author_name=master.first_name,
		text=f"Вложение: {filename}",
		attachment_path=relative_path,
		attachment_name=filename,
		sent_at=now,
		is_mine=True,
	)
	ticket.last_message = message.text
	ticket.last_message_at = now
	ticket.status = "waiting_for_response"
	db.add(message)
	db.commit()
	return CommunityMessageSchema(
		id=message.external_id,
		topic_id=ticket_id,
		author_name=message.author_name,
		text=message.text,
		sent_at=message.sent_at,
		is_mine=True,
		attachment_url=_attachment_url(relative_path),
		attachment_name=filename,
	)


@router.post("/support/tickets/{ticket_id}/cancel", response_model=SupportTicketSchema)
async def cancel_support_ticket(
	ticket_id: str,
	db: Session = Depends(get_db),
	master: models.Master = Depends(get_current_master),
) -> SupportTicketSchema:
	ticket = _get_master_support_ticket(db, master.id, ticket_id)

	ticket.status = "cancelled"
	db.commit()
	db.refresh(ticket)
	return SupportTicketSchema(
		id=ticket.external_id,
		title=ticket.title,
		author_name=ticket.author_name,
		created_at=ticket.created_at,
		last_message=ticket.last_message,
		last_message_at=ticket.last_message_at,
		status=ticket.status,
		unread_count=ticket.unread_count,
	)


@router.post("/devices/register")
async def register_device(
	body: DeviceRegisterRequest,
	db: Session = Depends(get_db),
	master: models.Master = Depends(get_current_master),
) -> dict[str, bool]:
	token = body.token.strip()
	platform = body.platform.strip().lower() or "ios"
	existing = db.scalar(select(models.DeviceToken).where(models.DeviceToken.token == token))
	now = datetime.now(timezone.utc)
	if existing is None:
		db.add(
			models.DeviceToken(
				master_id=master.id,
				token=token,
				platform=platform,
				created_at=now,
				updated_at=now,
			)
		)
	else:
		existing.master_id = master.id
		existing.platform = platform
		existing.updated_at = now
		db.add(existing)
	db.commit()
	return {"ok": True}


@router.get("/notifications", response_model=list[NotificationSchema])
async def list_notifications(
	limit: int = Query(default=50, ge=1, le=200),
	offset: int = Query(default=0, ge=0),
	db: Session = Depends(get_db),
	master: models.Master = Depends(get_current_master),
) -> list[NotificationSchema]:
	import json as json_lib

	rows = db.scalars(
		select(models.AppNotification)
		.where(models.AppNotification.master_id == master.id)
		.order_by(models.AppNotification.created_at.desc())
		.offset(offset)
		.limit(limit)
	).all()
	result = []
	for row in rows:
		payload = None
		if row.payload_json:
			try:
				payload = json_lib.loads(row.payload_json)
			except json_lib.JSONDecodeError:
				payload = None
		result.append(
			NotificationSchema(
				id=row.id,
				title=row.title,
				body=row.body,
				kind=row.kind,
				is_read=row.is_read,
				created_at=row.created_at,
				payload=payload if isinstance(payload, dict) else None,
			)
		)
	return result


@router.patch("/notifications/{notification_id}/read", response_model=NotificationSchema)
async def mark_notification_read(
	notification_id: int,
	db: Session = Depends(get_db),
	master: models.Master = Depends(get_current_master),
) -> NotificationSchema:
	import json as json_lib

	row = db.scalar(
		select(models.AppNotification).where(
			models.AppNotification.id == notification_id,
			models.AppNotification.master_id == master.id,
		)
	)
	if row is None:
		raise HTTPException(status_code=404, detail="Notification not found")
	row.is_read = True
	db.add(row)
	db.commit()
	db.refresh(row)
	payload = None
	if row.payload_json:
		try:
			payload = json_lib.loads(row.payload_json)
		except json_lib.JSONDecodeError:
			payload = None
	return NotificationSchema(
		id=row.id,
		title=row.title,
		body=row.body,
		kind=row.kind,
		is_read=row.is_read,
		created_at=row.created_at,
		payload=payload if isinstance(payload, dict) else None,
	)
