from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
	model_config = SettingsConfigDict(
		env_file=".env",
		env_file_encoding="utf-8",
		extra="ignore",
	)

	tbank_terminal_key: str = ""
	tbank_password: str = ""
	tbank_api_url: str = "https://securepay.tinkoff.ru/v2"
	public_base_url: str = "https://apis.beautytrust.ru"
	payment_amount_kopecks: int = 1000
	database_url: str = "postgresql+psycopg2://beautytrust:beautytrust@postgres:5432/beautytrust"
	admin_token: str = ""
	cors_origins: str = "*"
	uploads_dir: str = "data/uploads"
	demo_master_id: int = 1
	telegram_bot_token: str = ""
	telegram_bot_username: str = "BeautyTrust_bot"
	telegram_webhook_secret: str = ""
	auth_jwt_secret: str = "change-me-in-production"
	auth_access_token_minutes: int = 60 * 24 * 30
	zvonok_public_key: str = ""
	zvonok_campaign_id: str = ""
	zvonok_api_base_url: str = "https://zvonok.com"

	@property
	def tbank_configured(self) -> bool:
		return bool(self.tbank_terminal_key and self.tbank_password)

	@property
	def zvonok_configured(self) -> bool:
		return bool(self.zvonok_public_key and self.zvonok_campaign_id)

	@property
	def cors_origin_list(self) -> list[str]:
		if self.cors_origins.strip() == "*":
			return ["*"]
		return [item.strip() for item in self.cors_origins.split(",") if item.strip()]


settings = Settings()
