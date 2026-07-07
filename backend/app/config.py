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
	database_path: str = "data/payments.db"
	database_url: str = "postgresql+psycopg2://beautytrust:beautytrust@postgres:5432/beautytrust"
	admin_token: str = ""
	cors_origins: str = "*"
	uploads_dir: str = "data/uploads"
	demo_master_id: int = 1

	@property
	def tbank_configured(self) -> bool:
		return bool(self.tbank_terminal_key and self.tbank_password)

	@property
	def cors_origin_list(self) -> list[str]:
		if self.cors_origins.strip() == "*":
			return ["*"]
		return [item.strip() for item in self.cors_origins.split(",") if item.strip()]


settings = Settings()
