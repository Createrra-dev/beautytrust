from datetime import datetime

from pydantic import BaseModel, Field


class MasterReviewSchema(BaseModel):
	author_name: str
	rating: float
	text: str
	review_month: int
	review_year: int


class ReceivedMasterReviewSchema(BaseModel):
	id: int
	author_name: str
	rating: float
	text: str
	review_month: int
	review_year: int


class MasterSettingsSchema(BaseModel):
	push_notifications_enabled: bool = True
	email_notifications_enabled: bool = True
	marketing_notifications_enabled: bool = False
	visit_result_defaults_enabled: bool = True


class MasterSettingsUpdateRequest(BaseModel):
	push_notifications_enabled: bool | None = None
	email_notifications_enabled: bool | None = None
	marketing_notifications_enabled: bool | None = None
	visit_result_defaults_enabled: bool | None = None


class YClientsIntegrationSchema(BaseModel):
	enabled: bool = False
	partner_token: str = ""
	company_id: str = ""
	login: str = ""
	has_user_token: bool = False
	auth_pending: bool = False
	auth_recipient: str = ""
	last_sync_at: datetime | None = None
	last_sync_count: int = 0


class YClientsIntegrationUpdateRequest(BaseModel):
	enabled: bool | None = None
	partner_token: str | None = None
	company_id: str | None = None
	login: str | None = None
	password: str | None = None
	auth_code: str | None = None


class YClientsSyncResultSchema(BaseModel):
	imported: int
	updated: int
	skipped: int


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
	had_behavior_issues: bool = False
	was_unfriendly: bool = False
	had_scandal: bool = False
	threatened_complaints: bool = False
	demanded_discount: bool = False
	stole_from_salon: bool = False
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
	status: str = "scheduled"
	days_since_verified: int
	source: str = "manual"
	yclients_staff_name: str | None = None
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
	status: str | None = None
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
	onboarding_completed: bool = False


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
	is_closed: bool = False
	emoji: str = "💬"


class CommunityMessageSchema(BaseModel):
	id: str
	topic_id: str
	author_name: str
	text: str
	sent_at: datetime
	is_mine: bool
	attachment_url: str | None = None
	attachment_name: str | None = None


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


class TariffPlanSchema(BaseModel):
	id: str
	title: str
	monthly_price: int
	trial_label: str
	features: list[str]
	card_button_label: str
	audience: str
	is_popular: bool = False


class SubscriptionSchema(BaseModel):
	plan_id: str
	plan_title: str
	tariff_label: str
	expires_at: datetime | None = None
	is_active: bool
	monthly_price: int = 0


class SubscribeRequest(BaseModel):
	months: int = Field(default=1, ge=1, le=12)
	return_base_url: str | None = None


class SubscribeResponse(BaseModel):
	payment_id: str | None = None
	payment_url: str | None = None
	order_id: str | None = None
	amount: int
	months: int
	plan_id: str
	activated: bool = False
	subscription: SubscriptionSchema | None = None


class DeviceRegisterRequest(BaseModel):
	token: str = Field(min_length=8, max_length=512)
	platform: str = Field(default="ios", max_length=20)


class NotificationSchema(BaseModel):
	id: int
	title: str
	body: str
	kind: str
	is_read: bool
	created_at: datetime
	payload: dict | None = None


class AdminSupportReplyRequest(BaseModel):
	text: str = Field(min_length=1, max_length=4000)


class ClientReviewCreateRequest(BaseModel):
	rating: float = Field(ge=1.0, le=5.0)
	text: str = Field(min_length=3, max_length=2000)
	client_name: str | None = None


class ProfileStatsSchema(BaseModel):
	appointments_total: int
	appointments_scheduled: int
	appointments_completed: int
	appointments_no_show: int
	appointments_cancelled: int
	completion_rate: float
	avg_client_rating: float
	checks_total: int
	reviews_given: int
