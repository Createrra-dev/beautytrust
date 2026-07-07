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
	public_base_url: str = "http://127.0.0.1:8000"
	payment_amount_kopecks: int = 1000
	database_path: str = "data/payments.db"
	admin_token: str = ""

	@property
	def tbank_configured(self) -> bool:
		return bool(self.tbank_terminal_key and self.tbank_password)


settings = Settings()
