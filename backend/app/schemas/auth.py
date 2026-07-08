from typing import Literal

from pydantic import BaseModel, Field


class OtpSendRequest(BaseModel):
	phone: str = Field(min_length=10, max_length=20)
	channel: Literal["telegram", "flash_call"] = "telegram"
	is_registration: bool = False


class OtpSendResponse(BaseModel):
	session_id: str
	bot_url: str
	bot_username: str
	code_sent: bool
	expires_in: int
	channel: str


class OtpVerifyRequest(BaseModel):
	session_id: str
	code: str = Field(min_length=4, max_length=8)
	phone: str | None = Field(default=None, min_length=10, max_length=20)
	first_name: str | None = Field(default=None, min_length=1, max_length=120)


class PhoneCheckRequest(BaseModel):
	phone: str = Field(min_length=10, max_length=20)


class PhoneCheckResponse(BaseModel):
	registered: bool


class OtpCallStatusResponse(BaseModel):
	session_id: str
	channel: str
	call_id: int | None = None
	call_status: str | None = None
	call_status_display: str | None = None
	dial_status_display: str | None = None
	completed: bool = False


class AuthTokenResponse(BaseModel):
	access_token: str
	token_type: str = "bearer"
	master_id: int
	is_new_user: bool
