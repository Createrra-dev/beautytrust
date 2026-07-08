from datetime import datetime

from pydantic import BaseModel, Field


class MasterReviewSchema(BaseModel):
	author_name: str
	rating: float
	text: str
	review_month: int
	review_year: int


class ClientProfileSchema(BaseModel):
	phone: str
	rating_label: str
	reviews_average: float
	reviews_count: int
	no_shows_count: int
	scandals_count: int
	reviews: list[MasterReviewSchema]
	reliability_title: str
	reliability_subtitle: str


class ClientCheckResponse(BaseModel):
	client_name: str
	profile: ClientProfileSchema


class VisitResultSchema(BaseModel):
	punctuality: str
	paid_in_full: bool
	had_scandal: bool
	left_tips: bool
	comment: str | None = None


class AppointmentSchema(BaseModel):
	id: str
	client_name: str
	client_phone_digits: str
	service_name: str
	service_duration_label: str
	scheduled_at: datetime
	service_price: int
	client_rating: float
	risk_level: str
	days_since_verified: int
	visit_result: VisitResultSchema | None = None


class AppointmentCreateRequest(BaseModel):
	client_name: str
	client_phone_digits: str
	service_name: str
	service_duration_label: str
	scheduled_at: datetime
	service_price: int
	client_rating: float
	risk_level: str
	days_since_verified: int = 0


class AppointmentUpdateRequest(BaseModel):
	client_name: str | None = None
	client_phone_digits: str | None = None
	service_name: str | None = None
	service_duration_label: str | None = None
	scheduled_at: datetime | None = None
	service_price: int | None = None
	client_rating: float | None = None
	risk_level: str | None = None
	days_since_verified: int | None = None


class MasterServiceSchema(BaseModel):
	id: int
	name: str
	duration_label: str
	price: int
	is_owned: bool = False


class MasterServiceCreateRequest(BaseModel):
	name: str
	duration_label: str
	price: int


class MasterServiceUpdateRequest(BaseModel):
	name: str | None = None
	duration_label: str | None = None
	price: int | None = None


class DashboardStatsSchema(BaseModel):
	period_label: str
	protected_income: int
	income_trend_label: str
	income_trend_positive: bool
	sparkline_values: list[float]
	prevented_no_shows: int
	no_shows_trend_label: str
	completed_checks: int
	checks_trend_label: str


class DashboardPeriodSchema(BaseModel):
	year: int
	month: int
	label: str


class MasterProfileSchema(BaseModel):
	first_name: str
	badge_label: str
	rating: float
	reviews_count: int
	clients_count: int
	prevented_no_shows: int
	protected_income: int
	tariff_label: str
	avatar_url: str | None = None
	email: str | None = None
	phone_digits: str | None = None
	years_experience: int = 0


class MasterProfileUpdateRequest(BaseModel):
	first_name: str | None = None
	email: str | None = None
	badge_label: str | None = None


class CommunityTopicSchema(BaseModel):
	id: str
	title: str
	author_name: str
	created_at: datetime
	participant_count: int
	last_message: str
	last_message_at: datetime
	participant_initials: list[str]
	unread_count: int = 0
	is_pinned: bool = False
	emoji: str = "💬"


class CommunityMessageSchema(BaseModel):
	id: str
	topic_id: str
	author_name: str
	text: str
	sent_at: datetime
	is_mine: bool


class CommunityTopicCreateRequest(BaseModel):
	title: str
	story: str


class CommunityMessageCreateRequest(BaseModel):
	text: str


class SupportTicketSchema(BaseModel):
	id: str
	title: str
	author_name: str
	created_at: datetime
	last_message: str
	last_message_at: datetime
	status: str
	unread_count: int = 0


class SupportTicketCreateRequest(BaseModel):
	title: str
	description: str


class SupportMessageCreateRequest(BaseModel):
	text: str


class CheckHistoryRecordSchema(BaseModel):
	id: str
	client_name: str
	phone_digits: str
	rating: float
	risk_level: str
	checked_at: datetime


class PhoneCheckRequest(BaseModel):
	phone: str = Field(min_length=10, max_length=20)
